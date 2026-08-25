import 'package:blood_pressure_app/model/known_ble_device.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches advertised Beurer names without spaces', () {
    const known = KnownBleDevice(id: 'legacy-id', name: 'BM59');
    expect(known.matches('aa-bb', 'BM 59'), isTrue);
    expect(known.matches('aa-bb', 'Beurer BM59'), isTrue);
    expect(known.matches('aa-bb', 'X4 Smart'), isFalse);
  });

  test('still matches by stored id', () {
    const known = KnownBleDevice(id: 'abc', name: 'BM59');
    expect(known.matches('abc', 'Headphones'), isTrue);
  });

  test('does not match a longer model that only contains the stored name', () {
    const known = KnownBleDevice(id: 'legacy-id', name: 'BM59');
    expect(known.matches('aa-bb', 'BM590'), isFalse);
    expect(known.matches('aa-bb', 'X4 Smart'), isFalse);
  });

  test('matches a stored full name against an advertised model token', () {
    const known = KnownBleDevice(id: 'legacy-id', name: 'Beurer BM59');
    expect(known.matches('aa-bb', 'BM59'), isTrue);
    expect(known.matches('aa-bb', 'BM85'), isFalse);
  });

  test('defaults auto-sync on and restores it from json', () {
    const known = KnownBleDevice(id: 'abc', name: 'BM59');
    expect(known.autoSync, isTrue);
    expect(
      KnownBleDevice.fromJson({'id': 'abc', 'name': 'BM59'}).autoSync,
      isTrue,
    );
    expect(
      KnownBleDevice.fromJson({
        'id': 'abc',
        'name': 'BM59',
        'autoSync': false,
      }).autoSync,
      isFalse,
    );
    expect(known.copyWith(autoSync: false).autoSync, isFalse);
  });
}
