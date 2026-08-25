import 'package:blood_pressure_app/features/bluetooth/logic/characteristics/ble_measurement_data.dart';
import 'package:health_data_store/health_data_store.dart';

/// Identity used to treat a BLE reading as the same measurement as a diary entry.
String bleMeasurementKey(BleMeasurementData data) {
  final time = data.timestamp == null
      ? 'notime'
      : (data.timestamp!.millisecondsSinceEpoch ~/ 1000).toString();
  final sys = data.isMMHG ? data.systolic.round() : Pressure.kPa(data.systolic).mmHg;
  final dia = data.isMMHG ? data.diastolic.round() : Pressure.kPa(data.diastolic).mmHg;
  final pul = data.pulse?.round();
  return '$time|$sys|$dia|$pul';
}

/// Identity of a stored blood-pressure record for [bleMeasurementKey] comparison.
String bloodPressureRecordKey(BloodPressureRecord record) {
  final time = record.time.millisecondsSinceEpoch ~/ 1000;
  return '$time|${record.sys?.mmHg}|${record.dia?.mmHg}|${record.pul}';
}

/// Incoming measurements that are not already in [saved] and not repeated in
/// this batch. The first occurrence of each key is kept.
List<BleMeasurementData> newBleMeasurements(
  Iterable<BleMeasurementData> incoming,
  Iterable<BloodPressureRecord> saved,
) {
  final seen = saved.map(bloodPressureRecordKey).toSet();
  final fresh = <BleMeasurementData>[];
  for (final measurement in incoming) {
    final key = bleMeasurementKey(measurement);
    if (seen.contains(key)) continue;
    seen.add(key);
    fresh.add(measurement);
  }
  return fresh;
}
