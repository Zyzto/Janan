import 'package:blood_pressure_app/features/bluetooth/logic/ble_device_filter.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/ble_read_cubit.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches advertised blood pressure services', () {
    expect(isLikelyBloodPressureDevice(
      deviceId: '1',
      name: 'Unknown',
      serviceUUIDs: [UUID.fromString(BleReadCubit.defaultServiceUUID)],
    ), isTrue);
    expect(isLikelyBloodPressureDevice(
      deviceId: '1',
      name: 'Unknown',
      serviceUUIDs: [UUID.fromString(BleReadCubit.yonkerServiceUUID)],
    ), isTrue);
    expect(isLikelyBloodPressureDevice(
      deviceId: '1',
      name: 'Unknown',
      serviceUUIDs: [UUID.fromString(BleReadCubit.microlifeServiceUUID)],
    ), isTrue);
  });

  test('matches documented device names', () {
    expect(isLikelyBloodPressureName('X4 Smart'), isTrue);
    expect(isLikelyBloodPressureName('Beurer BM85'), isTrue);
    expect(isLikelyBloodPressureName('BLESmart_abc'), isTrue);
    expect(isLikelyBloodPressureName('Headphones'), isFalse);
    expect(isLikelyBloodPressureName(null), isFalse);
  });

  test('matches already paired devices', () {
    expect(isLikelyBloodPressureDevice(
      deviceId: 'abc',
      name: 'Headphones',
      serviceUUIDs: const [],
      knownDevices: const ['abc'],
    ), isTrue);
  });

  test('rejects unrelated advertisers', () {
    expect(isLikelyBloodPressureDevice(
      deviceId: '1',
      name: 'WH-1000XM4',
      serviceUUIDs: const [],
    ), isFalse);
  });
}
