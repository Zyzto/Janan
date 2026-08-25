import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_device_registry.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/gatt_blood_pressure_profile.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/microlife_profile.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/yonker_profile.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final registry = BleDeviceRegistry();
  UUID uuid(String raw) => UUID.fromString(raw);

  group('advertisement', () {
    test('matches GATT blood-pressure names and the 1810 service', () {
      expect(
        const GattBloodPressureProfile().matchesAdvertisement(
          name: 'BM59',
          serviceUUIDs: const [],
        ),
        isTrue,
      );
      expect(
        registry.resolveAdvertisement(
          name: 'Unknown',
          serviceUUIDs: [uuid(GattBloodPressureProfile.serviceUUID)],
        )?.id,
        'gatt-blood-pressure',
      );
    });

    test('matches Yonker names and the vendor service', () {
      expect(
        const YonkerProfile().matchesAdvertisement(
          name: 'YK-BPW5',
          serviceUUIDs: const [],
        ),
        isTrue,
      );
      expect(
        registry.resolveAdvertisement(
          name: 'Unknown',
          serviceUUIDs: [uuid(YonkerProfile.serviceUUID)],
        )?.id,
        'yonker',
      );
    });

    test('nameless fff0 looks like Microlife', () {
      expect(
        registry.resolveAdvertisement(
          name: 'Unknown',
          serviceUUIDs: [uuid('fff0')],
        )?.id,
        'microlife',
      );
    });
  });

  group('discovered GATT', () {
    test('nameless fff0 without characteristics is not enough', () {
      expect(
        registry.resolveDiscovered(
          name: null,
          serviceUUIDs: [uuid('fff0')],
          characteristicUUIDs: const [],
        ),
        isNull,
      );
    });

    test('fff1 and fff2 without fff4 is Microlife', () {
      expect(
        const MicrolifeProfile().matchesDiscovered(
          serviceUUIDs: [uuid('fff0')],
          characteristicUUIDs: [
            uuid(MicrolifeProfile.notifyCharacteristicUUID),
            uuid(MicrolifeProfile.writeCharacteristicUUID),
          ],
        ),
        isTrue,
      );
      expect(
        registry.resolveDiscovered(
          serviceUUIDs: [uuid('fff0')],
          characteristicUUIDs: [uuid('fff1'), uuid('fff2')],
        )?.id,
        'microlife',
      );
    });

    test('1810 is GATT blood pressure', () {
      expect(
        registry.resolveDiscovered(
          serviceUUIDs: [uuid(GattBloodPressureProfile.serviceUUID)],
          characteristicUUIDs: [uuid(GattBloodPressureProfile.characteristicUUID)],
        )?.id,
        'gatt-blood-pressure',
      );
    });

    test('yonker vendor service wins over a shared name', () {
      expect(
        registry.resolveDiscovered(
          name: 'YK-BPW5',
          serviceUUIDs: [uuid(YonkerProfile.serviceUUID)],
          characteristicUUIDs: [uuid(YonkerProfile.characteristicUUID)],
        )?.id,
        'yonker',
      );
    });

    test('fff4 without fff2 is Eufy P1', () {
      expect(
        registry.resolveDiscovered(
          name: 'eufy T9147',
          serviceUUIDs: [uuid('fff0')],
          characteristicUUIDs: [uuid('fff4'), uuid('fff1')],
        )?.id,
        'eufy-p1',
      );
    });

    test('fff4 plus fff2 is the unsupported P2 stub', () {
      expect(
        registry.resolveDiscovered(
          name: 'eufy T9149',
          serviceUUIDs: [uuid('fff0')],
          characteristicUUIDs: [uuid('fff4'), uuid('fff2')],
        )?.id,
        'eufy-p2',
      );
    });
  });
}
