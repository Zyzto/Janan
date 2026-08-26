import 'package:blood_pressure_app/domain/domain.dart';

/// Protocol-neutral body-weight reading from a scale.
class BleWeightData {
  /// Create a scale reading.
  const BleWeightData({
    required this.kg,
    required this.time,
    this.impedance,
  });

  /// Weight in kilograms.
  final double kg;

  /// When the reading was taken.
  final DateTime time;

  /// Optional bio-impedance in ohms, when the scale sent a valid value.
  final double? impedance;

  /// Convert to a diary record.
  BodyweightRecord asBodyweightRecord() => BodyweightRecord(
    time: time,
    weight: Weight.kg(kg),
    impedanceOhm: impedance,
  );

  /// Hundredths of a kilogram, used for duplicate detection.
  int get rawWeight => (kg * 100).round();
}
