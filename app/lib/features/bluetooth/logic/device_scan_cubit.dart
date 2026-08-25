// TODO: cleanup types
// ignore_for_file: strict_raw_type

import 'dart:async';

import 'package:blood_pressure_app/features/bluetooth/backend/bluetooth_backend.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/ble_device_filter.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/ble_read_cubit.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/bluetooth_cubit.dart';
import 'package:blood_pressure_app/logging.dart';
import 'package:blood_pressure_app/model/known_ble_device.dart';
import 'package:blood_pressure_app/model/storage/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'device_scan_state.dart';

/// A component to search for bluetooth devices .
///
/// For this to work the app must have access to the bluetooth adapter
/// ([BluetoothCubit]).
///
/// A device counts as recognized, when the user connected with it at least
/// once. Recognized devices connect automatically.
class DeviceScanCubit extends Cubit<DeviceScanState> with TypeLogger {
  /// Search for bluetooth devices that match the criteria or are known
  /// ([Settings.knownBleDev]).
  DeviceScanCubit({
    required BluetoothManager manager,
    required this.settings,
    this.autoRead = true,
  }): super(DeviceListLoading()) {
    _manager = manager;
    _startScanning();
  }

  /// Storage for known devices.
  late final Settings settings;

  /// When true, accepting a device starts a measurement read.
  final bool autoRead;

  late final BluetoothManager _manager;

  @override
  Future<void> close() async {
    final stopped = await _stopScanning();
    if (stopped) {
      await super.close();
    }
  }

  Future<void> _startScanning() async {
    try {
      await _manager.discovery.start(_onScanResult);
    } catch (e) {
      _onScanError(e);
    }
  }

  Future<bool> _stopScanning() async {
    try {
      await _manager.discovery.stop();
    } catch (err) {
      logger.severe('Failed to stop scanning', err);
      return false;
    }
    return true;
  }

  void _onScanResult(List<BluetoothDevice> devices) {
    logger.finer('_onScanResult devices: $devices');

    if (state is DeviceSelected) {
      return;
    }

    final knownHits = devices.where((dev) =>
      settings.knownBleDev.any((known) => known.matches(dev.deviceId, dev.name))).toList();

    if (knownHits.length == 1 && autoRead) {
      unawaited(_startRead(knownHits.first));
      return;
    }

    final likely = <BluetoothDevice>[];
    final other = <BluetoothDevice>[];
    for (final device in devices) {
      if (isLikelySupportedHealthBluetoothDevice(
        device,
        knownDevices: settings.knownBleDev,
      )) {
        likely.add(device);
      } else {
        other.add(device);
      }
    }

    if (likely.isEmpty && other.isEmpty) {
      emit(DeviceListLoading());
    } else if (likely.length == 1 && other.isEmpty) {
      emit(SingleDeviceAvailable(likely.first));
    } else {
      emit(DeviceListAvailable(likely, otherDevices: other));
    }
  }

  void _onScanError(Object error) {
    logger.severe('Error during device discovery', error);
  }

  /// Mark a new device as known and switch to selected device state asap.
  Future<void> acceptDevice(BluetoothDevice device) async {
    assert(state is! DeviceSelected);
    try {
      await _stopScanning();
    } catch (e) {
      _onScanError(e);
      return;
    }

    _rememberDevice(device);
    if (autoRead) {
      await _startRead(device);
    }
  }

  void _rememberDevice(BluetoothDevice device) {
    final list = settings.knownBleDev.toList();
    if (list.any((known) => known.matches(device.deviceId, device.name))) {
      settings.knownBleDev = [
        for (final known in list)
          if (known.matches(device.deviceId, device.name))
            known.copyWith(id: device.deviceId, name: device.name)
          else
            known,
      ];
      return;
    }
    list.add(KnownBleDevice(id: device.deviceId, name: device.name));
    settings.knownBleDev = list;
  }

  /// Stop discovering without closing the cubit.
  Future<void> pauseScan() => _stopScanning();

  /// Start discovering again after [pauseScan].
  Future<void> resumeScan() async {
    if (isClosed || state is DeviceSelected) return;
    await _startScanning();
  }

  Future<void> _startRead(BluetoothDevice device) async {
    await _stopScanning();
    if (isClosed) return;
    final readCubit = BleReadCubit(
      device: device.source.peripheral,
      cm: device.manager,
      deviceName: device.name,
    );
    emit(DeviceSelected(readCubit));
    unawaited(
      readCubit.takeMeasurement().onError(
        (e, stack) => logger.severe('takeMeasurement failed', e, stack),
      ),
    );
  }
}
