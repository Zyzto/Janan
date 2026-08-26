import 'package:blood_pressure_app/features/bluetooth/logic/characteristics/yonker_measurement_data.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_device_kind.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_device_profile.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_device_read_result.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_gatt_session.dart';
import 'package:blood_pressure_app/logging.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

/// Yonker / Yongrow / METIKO vendor blood-pressure service.
class YonkerProfile extends BleDeviceProfile with Loggable {
  /// Create the Yonker profile.
  const YonkerProfile();

  static const serviceUUID = 'cdeacd80-5235-4c07-8846-93a37ee6b86d';
  static const characteristicUUID = 'cdeacd81-5235-4c07-8846-93a37ee6b86d';

  @override
  String get id => 'yonker';

  @override
  String get displayFamily => 'Yonker';

  @override
  BleDeviceKind get kind => BleDeviceKind.bloodPressure;

  @override
  List<String> get nameTokens => const [
    'YK',
    'YONKER',
    'YONGROW',
    'METIKO',
  ];

  @override
  List<String> get advertisedServiceUUIDs => const [serviceUUID];

  @override
  bool matchesDiscovered({
    String? name,
    required Iterable<UUID> serviceUUIDs,
    required Iterable<UUID> characteristicUUIDs,
  }) => containsUuid(serviceUUIDs, serviceUUID);

  @override
  Future<BleDeviceReadResult> read(BleGattSession session) async {
    logDebug('YonkerProfile.read()');
    final gattService = session.service(serviceUUID);
    final gattCharacteristic = gattService == null
        ? null
        : session.characteristic(gattService, characteristicUUID);
    if (gattCharacteristic == null) {
      return BleDeviceReadFailure(
        'Device ${session.device.uuid} does not provide the expected yonker characteristic',
      );
    }

    final data = await session.collectNotifications(
      gattCharacteristic,
      settleFirst: false,
      decode: (value) {
        logDebug('Received yonker notification: $value');
        return YonkerMeasurementData.decode(value)?.asBleData;
      },
      isComplete: (_, all) => all.isNotEmpty,
    );
    if (data.isEmpty) {
      logWarning('Failed to decode yonker measurement for ${session.device}');
      return const BleDeviceReadFailure('Could not decode data');
    }
    return BleBloodPressureRead(data);
  }
}
