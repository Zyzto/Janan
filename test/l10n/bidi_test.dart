import 'package:blood_pressure_app/l10n/bidi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  test('isolateBidi wraps with FSI and PDI', () {
    expect(isolateBidi('note'), '\u2068note\u2069');
    expect(unwrapBidiIsolates(isolateBidi('ملاحظات')), 'ملاحظات');
  });

  test('isolateLtr keeps readings readable', () {
    expect(isolateLtr('120/80 mmHg'), '\u2068120/80 mmHg\u2069');
  });

  test('DateFormat with ar emits Arabic month names', () async {
    await initializeDateFormatting('ar');
    final label = DateFormat.yMMM('ar').format(DateTime(2024, 3, 15));
    expect(label.contains(RegExp(r'[A-Za-z]{3}')), isFalse);
    expect(label, isNot(contains('Mar')));
  });
}
