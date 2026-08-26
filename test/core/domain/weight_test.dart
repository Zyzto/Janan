import 'package:blood_pressure_app/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns the same value as constructed with', () {
    expect(Weight.mg(1234.45).mg, 1234.45);
    expect(Weight.g(1234.45).g, 1234.45);
    expect(Weight.kg(1234.45).kg, 1234.45);
    expect(Weight.gr(1234.45).gr, 1234.45);
  });

  test('equal across constructor typed', () {
    expect(Weight.mg(1000), Weight.g(1));
  });
}
