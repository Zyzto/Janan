import 'dart:async';

import 'package:blood_pressure_app/features/bluetooth/logic/characteristics/ble_measurement_data.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_device_read_result.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_device_registry.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_gatt_session.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/gatt_blood_pressure_profile.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/microlife_profile.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/yonker_profile.dart';
import 'package:blood_pressure_app/logging.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'ble_read_state.dart';

/// Connects to a BLE device, picks a [BleDeviceProfile], and emits the result.
class BleReadCubit extends Cubit<BleReadState> with TypeLogger {
  /// Start reading from [device].
  BleReadCubit({
    required this.device,
    required this.cm,
    this.deviceName,
    BleDeviceRegistry? registry,
  }) : registry = registry ?? defaultBleDeviceRegistry,
       super(BleReadInProgress());

  /// Bluetooth device to connect to.
  final Peripheral device;

  /// Central used for connect, discover, and disconnect.
  final CentralManager cm;

  /// Advertised name of [device], used by profiles for model quirks.
  final String? deviceName;

  /// Profiles consulted after GATT discovery.
  final BleDeviceRegistry registry;

  static const defaultServiceUUID = GattBloodPressureProfile.serviceUUID;
  static const defaultCharacteristicUUID = GattBloodPressureProfile.characteristicUUID;

  static const yonkerServiceUUID = YonkerProfile.serviceUUID;
  static const yonkerCharacteristicUUID = YonkerProfile.characteristicUUID;

  static const microlifeServiceUUID = MicrolifeProfile.serviceUUID;
  static const microlifeNotifyCharacteristicUUID = MicrolifeProfile.notifyCharacteristicUUID;
  static const microlifeWriteCharacteristicUUID = MicrolifeProfile.writeCharacteristicUUID;

  static const _connectTimeout = Duration(seconds: 20);

  bool _connected = false;

  /// Whether [advertisedName] belongs to a model known to send multi byte
  /// fields big endian instead of the little endian the spec requires.
  @visibleForTesting
  static bool isKnownBigEndianDevice(String? advertisedName) =>
      GattBloodPressureProfile.isKnownBigEndianDevice(advertisedName);

  Future<bool> _connectDevice() async {
    if (isClosed) return false;
    logger.info('Connecting to ${device.uuid}');
    final connected = Completer<bool>();
    final subscription = cm.connectionStateChanged
        .where((event) => event.peripheral == device)
        .listen((event) {
      if (connected.isCompleted) return;
      if (event.state == ConnectionState.connected) {
        connected.complete(true);
      }
    });
    try {
      await cm.connect(device);
      if (isClosed) return false;
      logger.finer('connect command send');
      final success = await connected.future.timeout(_connectTimeout);
      logger.finer('Connection result: $success');
      _connected = success;
      return success;
    } on TimeoutException {
      logger.warning('Timed out waiting for connection to ${device.uuid}');
      return false;
    } catch (error) {
      logger.finer('connect threw, checking if already connected: $error');
      if (isClosed) return false;
      if (connected.isCompleted) {
        _connected = await connected.future;
        return _connected;
      }
      try {
        await cm.discoverGATT(device).timeout(const Duration(seconds: 8));
        _connected = true;
        return true;
      } catch (_) {
        return false;
      }
    } finally {
      await subscription.cancel();
    }
  }

  /// Read measurements from the device and catch failures so the UI can recover.
  Future<void> takeMeasurement() async {
    try {
      await _takeMeasurement();
    } catch (error, stack) {
      logger.severe('takeMeasurement failed', error, stack);
      if (!isClosed && state is BleReadInProgress) {
        emit(BleReadFailure('Could not read from device: $error'));
      }
    }
  }

  Future<void> _takeMeasurement() async {
    logger.finest('takeMeasurement();');
    if (!await _connectDevice()) {
      if (!isClosed) {
        emit(BleReadFailure('Unable to connect to device: ${device.uuid}'));
      }
      return;
    }

    logger.finest('starting service discovery...');
    final services = await cm.discoverGATT(device);
    if (isClosed) return;
    if (services.isEmpty) {
      logger.warning('Device ${device.uuid} advertised no services after connecting');
    }

    final profile = registry.resolveDiscovered(
      name: deviceName,
      serviceUUIDs: services.map((service) => service.uuid),
      characteristicUUIDs: [
        for (final service in services)
          ...service.characteristics.map((characteristic) => characteristic.uuid),
      ],
    );
    if (profile == null) {
      emit(BleReadFailure(
        'Device ${device.uuid} does not advertise a supported service',
      ));
      return;
    }

    logger.finer('using profile ${profile.id} for $deviceName');
    final result = await profile.read(BleGattSession(
      device: device,
      cm: cm,
      services: services,
      deviceName: deviceName,
    ));
    switch (result) {
      case BleBloodPressureRead(:final measurements):
        if (measurements.isEmpty) {
          emit(BleReadFailure('No data received'));
        } else if (measurements.length == 1) {
          emit(BleReadSuccess(measurements.first));
        } else {
          emit(BleReadMultiple(measurements));
        }
      case BleDeviceReadFailure(:final reason):
        emit(BleReadFailure(reason));
    }
  }

  @mustCallSuper
  @override
  Future<void> close() async {
    if (_connected) {
      try {
        await cm.disconnect(device).timeout(const Duration(seconds: 2));
      } catch (error) {
        logger.warning('Failed to disconnect from ${device.uuid}: $error');
      }
    }
    await super.close();
  }

  /// Called after reading from a device returned multiple measurements and the
  /// user chose which measurement they wanted to add.
  Future<void> useMeasurement(BleMeasurementData data) async {
    assert(state is! BleReadSuccess);
    emit(BleReadSuccess(data));
  }
}
