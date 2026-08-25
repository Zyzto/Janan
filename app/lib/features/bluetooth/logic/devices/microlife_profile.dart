import 'dart:async';
import 'dart:typed_data';

import 'package:blood_pressure_app/features/bluetooth/logic/characteristics/microlife_measurement_data.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/characteristics/microlife_protocol.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_device_kind.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_device_profile.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_device_read_result.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_gatt_session.dart';
import 'package:blood_pressure_app/logging.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

/// Microlife vendor protocol on `fff0` (`fff1` notify, `fff2` write).
class MicrolifeProfile extends BleDeviceProfile with TypeLogger {
  /// Create the Microlife profile.
  const MicrolifeProfile();

  static const serviceUUID = 'fff0';
  static const notifyCharacteristicUUID = 'fff1';
  static const writeCharacteristicUUID = 'fff2';

  static const _responseTimeout = Duration(seconds: 30);

  @override
  String get id => 'microlife';

  @override
  String get displayFamily => 'Microlife';

  @override
  BleDeviceKind get kind => BleDeviceKind.bloodPressure;

  @override
  List<String> get nameTokens => const [
    'BP3GY',
    'MICROLIFE',
  ];

  @override
  List<String> get advertisedServiceUUIDs => const [serviceUUID];

  @override
  bool matchesDiscovered({
    String? name,
    required Iterable<UUID> serviceUUIDs,
    required Iterable<UUID> characteristicUUIDs,
  }) =>
      containsUuid(serviceUUIDs, serviceUUID)
      && containsUuid(characteristicUUIDs, notifyCharacteristicUUID)
      && containsUuid(characteristicUUIDs, writeCharacteristicUUID)
      && !containsUuid(characteristicUUIDs, 'fff4');

  @override
  Future<BleDeviceReadResult> read(BleGattSession session) async {
    logger.finest('MicrolifeProfile.read()');
    final gattService = session.service(serviceUUID);
    final notifyCharacteristic = gattService == null
        ? null
        : session.characteristic(gattService, notifyCharacteristicUUID);
    final writeCharacteristic = gattService == null
        ? null
        : session.characteristic(gattService, writeCharacteristicUUID);
    if (notifyCharacteristic == null || writeCharacteristic == null) {
      return BleDeviceReadFailure(
        'Device ${session.device.uuid} does not provide the expected microlife characteristics',
      );
    }

    final buffer = <int>[];
    Completer<Uint8List>? pending;
    final subscription = session.notifications(notifyCharacteristic).listen((value) {
      logger.fine('Microlife notification: $value');
      buffer.addAll(value);
      final expectedLength = MicrolifeProtocol.expectedFrameLength(buffer);
      if (expectedLength == null || buffer.length < expectedLength) return;
      final frame = buffer.sublist(0, expectedLength);
      buffer.clear();
      final completer = pending;
      if (completer == null || completer.isCompleted) return;
      final payload = MicrolifeProtocol.parseResponsePayload(frame);
      if (payload == null) {
        completer.completeError(StateError('Invalid microlife frame: $frame'));
      } else {
        completer.complete(payload);
      }
    });

    Future<Uint8List> send(
      List<int> command, {
      bool waitForResponse = true,
      Duration timeout = _responseTimeout,
    }) async {
      buffer.clear();
      Completer<Uint8List>? completer;
      if (waitForResponse) {
        completer = Completer<Uint8List>();
        pending = completer;
      }
      await session.write(writeCharacteristic, command);
      if (completer == null) return Uint8List(0);
      try {
        return await completer.future.timeout(timeout);
      } finally {
        if (identical(pending, completer)) pending = null;
      }
    }

    try {
      await session.setNotify(notifyCharacteristic, enabled: true);
      try {
        await send(
          MicrolifeProtocol.buildSetTimeCommand(DateTime.now()),
          timeout: const Duration(seconds: 10),
        );
      } catch (error) {
        logger.warning('Microlife set time failed, continuing: $error');
      }

      final payload = await send(MicrolifeProtocol.getMeasurementsCommand);
      final measurements = MicrolifeMeasurementData.decodeMeasurements(payload)
          .map((measurement) => measurement.asBleData)
          .toList();

      try {
        await send(MicrolifeProtocol.disconnectCommand, waitForResponse: false);
      } catch (error) {
        logger.finer('Microlife disconnect command failed: $error');
      }

      if (measurements.isEmpty) {
        return const BleDeviceReadFailure('No data received');
      }
      return BleBloodPressureRead(measurements);
    } on TimeoutException {
      logger.warning('Microlife communication timed out for ${session.device.uuid}');
      return const BleDeviceReadFailure('No data received');
    } catch (error) {
      logger.warning('Microlife communication failed: $error');
      return const BleDeviceReadFailure('Could not decode data');
    } finally {
      await subscription.cancel();
      try {
        await session.setNotify(notifyCharacteristic, enabled: false);
      } catch (error) {
        logger.finer('Failed to disable microlife notifications: $error');
      }
    }
  }
}
