import 'package:blood_pressure_app/features/export_import/model/excel_converter.dart';
import 'package:blood_pressure_app/model/storage/storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'record_formatter_test.dart';

void main() {
  test('escapes note text so SpreadsheetML stays valid XML', () {
    final converter = ExcelConverter(
      ExcelExportSettings(),
      ExportColumnsManager(),
      const [],
      ExportSettings(),
    );

    final xml = converter.create([mockEntry(note: 'Dose < 5 & recovery > 2')]);

    expect(xml, contains('Dose &lt; 5 &amp; recovery &gt; 2'));
    expect(xml, isNot(contains('Dose < 5 & recovery > 2')));
  });

  test('replaces control characters that XML 1.0 cannot represent', () {
    final converter = ExcelConverter(
      ExcelExportSettings(),
      ExportColumnsManager(),
      const [],
      ExportSettings(),
    );

    final xml = converter.create([mockEntry(note: 'before\u0001after')]);

    expect(xml, contains('before\ufffdafter'));
    expect(xml, isNot(contains('\u0001')));
  });
}
