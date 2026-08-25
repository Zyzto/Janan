import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_device_kind.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_device_profile.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/eufy_p1_scale_profile.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/eufy_p2_unsupported_profile.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/gatt_blood_pressure_profile.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/microlife_profile.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/yonker_profile.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

/// Ordered list of supported BLE protocols.
///
/// Scan uses [resolveAdvertisement]. After GATT discovery, [resolveDiscovered]
/// picks the first profile whose characteristic signature matches.
class BleDeviceRegistry {
  /// Create a registry. [profiles] defaults to the built-in families.
  BleDeviceRegistry([List<BleDeviceProfile>? profiles])
      : profiles = List.unmodifiable(profiles ?? defaultProfiles);

  /// Built-in priority: GATT BP, Yonker, Eufy P1, Eufy P2 stub, Microlife.
  static const defaultProfiles = <BleDeviceProfile>[
    GattBloodPressureProfile(),
    YonkerProfile(),
    EufyP1ScaleProfile(),
    EufyP2UnsupportedProfile(),
    MicrolifeProfile(),
  ];

  /// Profiles in resolution order.
  final List<BleDeviceProfile> profiles;

  /// First profile that claims this advertisement, or null.
  BleDeviceProfile? resolveAdvertisement({
    String? name,
    required Iterable<UUID> serviceUUIDs,
  }) {
    for (final profile in profiles) {
      if (profile.matchesAdvertisement(name: name, serviceUUIDs: serviceUUIDs)) {
        return profile;
      }
    }
    return null;
  }

  /// First profile that claims the discovered GATT layout, or null.
  BleDeviceProfile? resolveDiscovered({
    String? name,
    required Iterable<UUID> serviceUUIDs,
    required Iterable<UUID> characteristicUUIDs,
  }) {
    for (final profile in profiles) {
      if (profile.matchesDiscovered(
        name: name,
        serviceUUIDs: serviceUUIDs,
        characteristicUUIDs: characteristicUUIDs,
      )) {
        return profile;
      }
    }
    return null;
  }

  /// Whether any profile treats this advertisement as a supported device.
  bool anyAdvertisementMatch({
    String? name,
    required Iterable<UUID> serviceUUIDs,
  }) => resolveAdvertisement(name: name, serviceUUIDs: serviceUUIDs) != null;

  /// Whether a weight profile matches this advertised name.
  bool isLikelyWeightScaleName(String? name) => profiles.any((profile) =>
      profile.kind == BleDeviceKind.weight
      && profile.matchesAdvertisement(name: name, serviceUUIDs: const []));

  /// Whether this advertised name is an Eufy C1/P1 we can read without auth.
  bool isEufyP1ScaleName(String? name) => const EufyP1ScaleProfile()
      .matchesAdvertisement(name: name, serviceUUIDs: const []);
}

/// App-wide registry used by scan and read.
final defaultBleDeviceRegistry = BleDeviceRegistry();
