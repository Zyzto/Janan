import 'package:blood_pressure_app/features/bluetooth/backend/bluetooth_backend.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_device_registry.dart';
import 'package:blood_pressure_app/model/known_ble_device.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

/// Whether [advertisedName] looks like a documented blood-pressure meter.
bool isLikelyBloodPressureName(String? advertisedName) =>
    defaultBleDeviceRegistry.resolveAdvertisement(
      name: advertisedName,
      serviceUUIDs: const [],
    ) != null
    && !defaultBleDeviceRegistry.isLikelyWeightScaleName(advertisedName);

/// Whether a scanned device should be shown as a likely blood-pressure meter.
bool isLikelyBloodPressureDevice({
  required String deviceId,
  required String name,
  required Iterable<UUID> serviceUUIDs,
  List<KnownBleDevice> knownDevices = const [],
}) {
  if (knownDevices.any((device) => device.matches(deviceId, name))) {
    return true;
  }
  if (defaultBleDeviceRegistry.isLikelyWeightScaleName(name)) {
    return false;
  }
  return defaultBleDeviceRegistry.anyAdvertisementMatch(
    name: name,
    serviceUUIDs: serviceUUIDs,
  );
}

/// [isLikelyBloodPressureDevice] using a backend [BluetoothDevice].
bool isLikelyBloodPressureBluetoothDevice(
  BluetoothDevice device, {
  List<KnownBleDevice> knownDevices = const [],
}) => isLikelyBloodPressureDevice(
  deviceId: device.deviceId,
  name: device.name,
  serviceUUIDs: device.source.advertisement.serviceUUIDs,
  knownDevices: knownDevices,
);

/// Whether [advertisedName] is an Eufy C1/P1 scale we can read without auth.
bool isEufyP1ScaleName(String? advertisedName) =>
    defaultBleDeviceRegistry.isEufyP1ScaleName(advertisedName);

/// Whether [advertisedName] looks like a Eufy / 1byone body scale.
bool isLikelyWeightScaleName(String? advertisedName) =>
    defaultBleDeviceRegistry.isLikelyWeightScaleName(advertisedName);

/// Whether a scanned device should be treated as a supported health device.
bool isLikelySupportedHealthDevice({
  required String deviceId,
  required String name,
  required Iterable<UUID> serviceUUIDs,
  List<KnownBleDevice> knownDevices = const [],
}) {
  if (knownDevices.any((device) => device.matches(deviceId, name))) {
    return true;
  }
  return defaultBleDeviceRegistry.anyAdvertisementMatch(
    name: name,
    serviceUUIDs: serviceUUIDs,
  );
}

/// [isLikelySupportedHealthDevice] using a backend [BluetoothDevice].
bool isLikelySupportedHealthBluetoothDevice(
  BluetoothDevice device, {
  List<KnownBleDevice> knownDevices = const [],
}) => isLikelySupportedHealthDevice(
  deviceId: device.deviceId,
  name: device.name,
  serviceUUIDs: device.source.advertisement.serviceUUIDs,
  knownDevices: knownDevices,
);
