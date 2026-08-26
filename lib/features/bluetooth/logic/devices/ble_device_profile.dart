import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_device_kind.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_device_read_result.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_gatt_session.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_name.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

/// One supported BLE protocol: how to recognize it and how to read it.
abstract class BleDeviceProfile {
  /// Create a profile.
  const BleDeviceProfile();

  /// Stable id for logs and tests.
  String get id;

  /// Human-readable family name.
  String get displayFamily;

  /// What a successful read produces.
  BleDeviceKind get kind;

  /// Advertised-name fragments, compared after [normalizeBleName].
  List<String> get nameTokens => const [];

  /// Service UUIDs this family advertises.
  List<String> get advertisedServiceUUIDs => const [];

  /// Whether a scan result looks like this family.
  bool matchesAdvertisement({
    String? name,
    required Iterable<UUID> serviceUUIDs,
  }) {
    if (bleNameContainsAnyToken(name, nameTokens)) return true;
    return serviceUUIDs.any(_isAdvertisedService);
  }

  /// Whether discovered GATT objects belong to this family.
  ///
  /// This is the real check. Advertisement UUIDs can collide (shared `fff0`).
  bool matchesDiscovered({
    String? name,
    required Iterable<UUID> serviceUUIDs,
    required Iterable<UUID> characteristicUUIDs,
  });

  /// Talk to the connected device and return measurements or a failure.
  Future<BleDeviceReadResult> read(BleGattSession session);

  bool _isAdvertisedService(UUID uuid) =>
      advertisedServiceUUIDs.any((raw) => uuid == UUID.fromString(raw));
}

/// Whether [uuids] contains [raw].
bool containsUuid(Iterable<UUID> uuids, String raw) =>
    uuids.any((uuid) => uuid == UUID.fromString(raw));
