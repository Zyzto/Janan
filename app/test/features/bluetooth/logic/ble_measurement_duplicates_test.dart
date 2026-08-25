import 'package:blood_pressure_app/features/bluetooth/logic/ble_measurement_duplicates.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/characteristics/ble_measurement_data.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_weight_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_data_store/health_data_store.dart';

void main() {
  final time = DateTime.utc(2026, 4, 5, 16, 19, 10);

  BleMeasurementData reading({
    DateTime? timestamp,
    double sys = 145,
    double dia = 81,
    double? pulse = 80,
  }) => BleMeasurementData(
    systolic: sys,
    diastolic: dia,
    meanArterialPressure: 102,
    isMMHG: true,
    pulse: pulse,
    timestamp: timestamp ?? time,
  );

  test('keeps the first copy and drops later copies in the same dump', () {
    final first = reading();
    final second = reading();
    expect(newBleMeasurements([first, second], const []), [first]);
  });

  test('drops measurements already in the diary', () {
    final incoming = reading();
    final saved = [
      BloodPressureRecord(
        time: time,
        sys: Pressure.mmHg(145),
        dia: Pressure.mmHg(81),
        pul: 80,
      ),
    ];
    expect(newBleMeasurements([incoming], saved), isEmpty);
  });

  test('keeps a measurement with the same time but different values', () {
    final incoming = reading(sys: 150);
    final saved = [
      BloodPressureRecord(
        time: time,
        sys: Pressure.mmHg(145),
        dia: Pressure.mmHg(81),
        pul: 80,
      ),
    ];
    expect(newBleMeasurements([incoming], saved), [incoming]);
  });

  test('drops a scale reading already saved within five minutes', () {
    final incoming = BleWeightData(kg: 102.3, time: time);
    final saved = [
      BodyweightRecord(time: time.add(const Duration(minutes: 2)), weight: Weight.kg(102.3)),
    ];
    expect(newBleWeights([incoming], saved), isEmpty);
  });

  test('upgrades a recent weight-only save when impedance arrives', () {
    final incoming = BleWeightData(kg: 102.3, time: time, impedance: 500);
    final saved = [
      BodyweightRecord(time: time, weight: Weight.kg(102.3)),
    ];
    final upgrades = bleWeightsToUpgrade([incoming], saved);
    expect(upgrades, hasLength(1));
    expect(upgrades.single.$2.impedance, closeTo(500, 0.001));
  });
}
