import 'package:blood_pressure_app/l10n/western_digits.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  test('toWesternDigits converts Eastern Arabic and Persian digits', () {
    expect(toWesternDigits('٢٢:١٠ ٢٦-٠٨-٢٠٢٦'), '22:10 26-08-2026');
    expect(toWesternDigits('۱۴۰۴'), '1404');
    expect(toWesternDigits('120/80'), '120/80');
  });

  test('WesternDateFormat keeps Arabic month names and Latin digits', () {
    final date = DateTime(2026, 8, 26, 22, 10);
    expect(
      WesternDateFormat('HH:mm dd-MM-yyyy', 'ar').format(date),
      '22:10 26-08-2026',
    );
    expect(
      WesternDateFormat('HH:mm dd-MM-yyyy', 'ar').format(date),
      isNot(contains(RegExp('[٠-٩۰-۹]'))),
    );
    final month = WesternDateFormat.yMMM('ar').format(DateTime(2024, 3, 15));
    expect(month.contains(RegExp(r'[A-Za-z]{3}')), isFalse);
    expect(month, isNot(contains('Mar')));
    expect(month, contains('2024'));
  });
}
