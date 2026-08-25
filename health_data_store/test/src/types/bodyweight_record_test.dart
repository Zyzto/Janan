import 'package:health_data_store/src/types/bodyweight_record.dart';
import 'package:health_data_store/src/types/units/weight.dart';
import 'package:test/test.dart';

void main() {
  test('should initialize', () {
    final weight = BodyweightRecord(
      time: DateTime.now(),
      weight: Weight.kg(60),
    );
    expect(weight.weight, Weight.kg(60));
    expect(weight.impedanceOhm, isNull);
  });
  test('stores optional impedance', () {
    final weight = BodyweightRecord(
      time: DateTime.now(),
      weight: Weight.kg(60),
      impedanceOhm: 512.4,
    );
    expect(weight.impedanceOhm, closeTo(512.4, 0.0001));
  });
}

BodyweightRecord mockWeight({
  int? time,
  double? kg,
  double? impedanceOhm,
}) =>
    BodyweightRecord(
      time: time != null
          ? DateTime.fromMillisecondsSinceEpoch(time)
          : DateTime.now(),
      weight: Weight.kg(kg ?? 42.0),
      impedanceOhm: impedanceOhm,
    );
