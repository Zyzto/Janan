/// Whether an increase in a metric is considered better or worse.
enum MetricPolarity {
  /// A lower value is an improvement (weight, fat, blood pressure).
  lowerIsBetter,

  /// A higher value is an improvement (muscle, water).
  higherIsBetter,

  /// Direction is shown without a good/bad color (BMR).
  neutral,
}

/// Visual tone for a change chip.
enum MetricChangeTone {
  /// Change moved in the preferred direction.
  better,

  /// Change moved against the preferred direction.
  worse,

  /// No polarity, or the value did not move.
  neutral,
}

/// Difference between a current metric and the previous measurement.
class MetricChange {
  /// Compare [current] to an optional [previous] value.
  const MetricChange({
    required this.current,
    this.previous,
    this.polarity = MetricPolarity.lowerIsBetter,
    this.unchangedEpsilon = 0.05,
  });

  /// Value on the opened measurement.
  final double current;

  /// Value on the previous measurement, when one exists.
  final double? previous;

  /// How to color an increase versus a decrease.
  final MetricPolarity polarity;

  /// Absolute delta treated as unchanged.
  final double unchangedEpsilon;

  /// [current] minus [previous], or null when there is nothing to compare.
  double? get delta => previous == null ? null : current - previous!;

  /// Whether a previous value is available.
  bool get hasComparison => previous != null;

  /// Whether the absolute delta is within [unchangedEpsilon].
  bool get isUnchanged =>
      delta != null && delta!.abs() < unchangedEpsilon;

  /// Whether the value rose by at least [unchangedEpsilon].
  bool get increased => delta != null && delta! >= unchangedEpsilon;

  /// Whether the value fell by at least [unchangedEpsilon].
  bool get decreased => delta != null && delta! <= -unchangedEpsilon;

  /// Color tone for the change chip.
  MetricChangeTone get tone {
    if (!hasComparison || isUnchanged || polarity == MetricPolarity.neutral) {
      return MetricChangeTone.neutral;
    }
    final improved = polarity == MetricPolarity.lowerIsBetter ? decreased : increased;
    return improved ? MetricChangeTone.better : MetricChangeTone.worse;
  }

  /// Absolute delta formatted for display.
  String formatAbsDelta(int fractionDigits) {
    final value = delta?.abs();
    if (value == null) return '';
    return _trimZeros(value.toStringAsFixed(fractionDigits));
  }

  static String _trimZeros(String value) {
    if (!value.contains('.')) return value;
    while (value.endsWith('0')) {
      value = value.substring(0, value.length - 1);
    }
    if (value.endsWith('.')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
