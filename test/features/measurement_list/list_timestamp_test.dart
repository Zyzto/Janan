import 'package:blood_pressure_app/features/measurement_list/list_timestamp.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  test('shows month name and day', () {
    expect(formatListTimestamp(DateTime(2026, 8, 25, 7, 42)), 'Aug 25');
    expect(formatListTimestamp(DateTime(2026, 8, 24, 21, 5)), 'Aug 24');
    expect(formatListTimestamp(DateTime(2026, 3, 4, 8, 0)), 'Mar 4');
    expect(formatListTimestamp(DateTime(2023, 1, 1, 0, 0)), 'Jan 1');
  });

  test('localizes month name for Arabic', () {
    final stamp = formatListTimestamp(DateTime(2026, 8, 26), 'ar');
    expect(stamp, isNot(contains('Aug')));
    expect(stamp.contains(RegExp(r'[A-Za-z]{3}')), isFalse);
    expect(stamp, contains('26'));
    expect(stamp, isNot(contains('٢٦')));
  });
}
