import 'package:blood_pressure_app/features/measurement_list/metric_info.dart';
import 'package:blood_pressure_app/model/body_sex.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MetricInfo resolve(
    MetricKind kind,
    double current, {
    BodySex? sex,
    double? heightCm,
    double? weightKg,
    int sysWarn = 120,
    int diaWarn = 80,
  }) => MetricInfo.resolve(
    kind: kind,
    current: current,
    formattedValue: '$current',
    sex: sex,
    heightCm: heightCm,
    weightKg: weightKg,
    sysWarn: sysWarn,
    diaWarn: diaWarn,
  );

  test('classifies WHO BMI bands', () {
    expect(resolve(MetricKind.bmi, 17).currentBand?.id, 'underweight');
    expect(resolve(MetricKind.bmi, 18.5).currentBand?.id, 'normal');
    expect(resolve(MetricKind.bmi, 24.9).currentBand?.id, 'normal');
    expect(resolve(MetricKind.bmi, 25).currentBand?.id, 'overweight');
    expect(resolve(MetricKind.bmi, 29.9).currentBand?.id, 'overweight');
    expect(resolve(MetricKind.bmi, 30).currentBand?.id, 'obesity');
  });

  test('uses sex-specific body-fat ranges', () {
    expect(resolve(MetricKind.bodyFat, 15, sex: BodySex.male).currentBand?.id, 'typical');
    expect(resolve(MetricKind.bodyFat, 8, sex: BodySex.male).currentBand?.id, 'low');
    expect(resolve(MetricKind.bodyFat, 25, sex: BodySex.male).currentBand?.id, 'high');
    expect(resolve(MetricKind.bodyFat, 22, sex: BodySex.female).currentBand?.id, 'typical');
    expect(resolve(MetricKind.bodyFat, 15, sex: BodySex.female).currentBand?.id, 'low');

    final unknown = resolve(MetricKind.bodyFat, 15);
    expect(unknown.bands.map((band) => band.id), containsAll(['typicalMen', 'typicalWomen']));
    expect(unknown.currentBand?.id, 'typicalMen');
  });

  test('uses sex-specific water ranges', () {
    expect(resolve(MetricKind.water, 55, sex: BodySex.male).currentBand?.id, 'typical');
    expect(resolve(MetricKind.water, 40, sex: BodySex.male).currentBand?.id, 'low');
    expect(resolve(MetricKind.water, 50, sex: BodySex.female).currentBand?.id, 'typical');
    expect(resolve(MetricKind.water, 40, sex: BodySex.female).currentBand?.id, 'low');

    final unknown = resolve(MetricKind.water, 52);
    expect(unknown.bands.map((band) => band.id), containsAll(['typicalMen', 'typicalWomen']));
  });

  test('builds a BP warn line from the configured warn values', () {
    expect(
      resolve(MetricKind.sys, 140, sysWarn: 135).warnLabel,
      'Warn at 135',
    );
    expect(
      resolve(MetricKind.dia, 90, diaWarn: 85).warnLabel,
      'Warn at 85',
    );
    expect(resolve(MetricKind.sys, 118).currentBand?.id, 'normal');
    expect(resolve(MetricKind.sys, 124).currentBand?.id, 'elevated');
    expect(resolve(MetricKind.sys, 130).currentBand?.id, 'high');
    expect(resolve(MetricKind.dia, 79).currentBand?.id, 'normal');
    expect(resolve(MetricKind.dia, 80).currentBand?.id, 'high');
  });

  test('classifies pulse and weight healthy band', () {
    expect(resolve(MetricKind.pulse, 55).currentBand?.id, 'low');
    expect(resolve(MetricKind.pulse, 72).currentBand?.id, 'typical');
    expect(resolve(MetricKind.pulse, 110).currentBand?.id, 'high');

    final weight = resolve(MetricKind.weight, 70, heightCm: 180);
    expect(weight.currentBand?.id, 'healthy');
    expect(weight.bands.single.interval, contains('kg'));
  });
}
