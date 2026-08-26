import 'package:blood_pressure_app/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('should create DateTime correctly', () {
    final t = DateTimeS.fromSecondsSinceEpoch(42);
    expect(t.millisecondsSinceEpoch, 42 * 1000);
  });

  test('should return time since epoch correctly', () {
    final t = DateTimeS.fromSecondsSinceEpoch(42);
    expect(t.secondsSinceEpoch, 42);
  });
}
