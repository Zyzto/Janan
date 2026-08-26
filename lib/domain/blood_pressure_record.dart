import 'package:blood_pressure_app/domain/units/pressure.dart';

/// Immutable representation of a blood pressure measurement.
class BloodPressureRecord {
  /// Create a immutable representation of a blood pressure measurement.
  const BloodPressureRecord({
    required this.time,
    this.sys,
    this.dia,
    this.pul,
  });

  /// Timestamp when the measurement was taken.
  final DateTime time;

  /// Systolic value of the measurement.
  final Pressure? sys;

  /// Diastolic value of the measurement.
  final Pressure? dia;

  /// Pulse value of the measurement in bpm.
  final int? pul;

  BloodPressureRecord copyWith({
    DateTime? time,
    Pressure? sys,
    Pressure? dia,
    int? pul,
  }) =>
      BloodPressureRecord(
        time: time ?? this.time,
        sys: sys ?? this.sys,
        dia: dia ?? this.dia,
        pul: pul ?? this.pul,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BloodPressureRecord &&
          time == other.time &&
          sys == other.sys &&
          dia == other.dia &&
          pul == other.pul;

  @override
  int get hashCode => Object.hash(time, sys, dia, pul);
}
