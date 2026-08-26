import 'package:blood_pressure_app/features/measurement_list/metric_change.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('has no comparison without a previous value', () {
    const change = MetricChange(current: 80);
    expect(change.hasComparison, isFalse);
    expect(change.delta, isNull);
    expect(change.formatAbsDelta(1), isEmpty);
  });

  test('detects an increase and decrease', () {
    const down = MetricChange(current: 80, previous: 90);
    expect(down.decreased, isTrue);
    expect(down.increased, isFalse);
    expect(down.formatAbsDelta(0), '10');

    const up = MetricChange(current: 95, previous: 90);
    expect(up.increased, isTrue);
    expect(up.decreased, isFalse);
  });

  test('treats small deltas as unchanged', () {
    const change = MetricChange(current: 80.02, previous: 80.0);
    expect(change.isUnchanged, isTrue);
    expect(change.tone, MetricChangeTone.neutral);
  });

  test('colors lower-is-better metrics', () {
    expect(
      const MetricChange(current: 80, previous: 90).tone,
      MetricChangeTone.better,
    );
    expect(
      const MetricChange(current: 95, previous: 90).tone,
      MetricChangeTone.worse,
    );
  });

  test('colors higher-is-better metrics', () {
    expect(
      const MetricChange(
        current: 42,
        previous: 40,
        polarity: MetricPolarity.higherIsBetter,
      ).tone,
      MetricChangeTone.better,
    );
    expect(
      const MetricChange(
        current: 38,
        previous: 40,
        polarity: MetricPolarity.higherIsBetter,
      ).tone,
      MetricChangeTone.worse,
    );
  });

  test('keeps BMR and similar metrics neutral', () {
    expect(
      const MetricChange(
        current: 2000,
        previous: 1900,
        polarity: MetricPolarity.neutral,
      ).tone,
      MetricChangeTone.neutral,
    );
  });

  test('trims trailing zeros from the delta', () {
    expect(
      const MetricChange(current: 80.5, previous: 81.0).formatAbsDelta(2),
      '0.5',
    );
  });
}
