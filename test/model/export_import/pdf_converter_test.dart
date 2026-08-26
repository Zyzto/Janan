import 'package:blood_pressure_app/features/export_import/model/pdf_converter.dart';
import 'package:blood_pressure_app/features/settings/app_settings.dart';
import 'package:blood_pressure_app/model/storage/storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';
import 'csv_converter_test.dart';

void main() {
  setUp(() async {
    await createTestSettings();
  });

  test('should not return empty data', () async {
    final converter = PdfConverter(
      PdfExportSettings(),
      AppSettings.fromController(testSettingsController!),
      ExportColumnsManager(),
      ExportSettings(),
    );
    final pdf = await converter.create(createRecords());
    expect(pdf.length, isNonZero);
  });
  test('generated data length should be consistent', () async {
    final converter = PdfConverter(
      PdfExportSettings(),
      AppSettings.fromController(testSettingsController!),
      ExportColumnsManager(),
      ExportSettings(),
    );
    final pdf = await converter.create(createRecords());
    final converter2 = PdfConverter(
      PdfExportSettings(),
      AppSettings.fromController(testSettingsController!),
      ExportColumnsManager(),
      ExportSettings(),
    );
    final pdf2 = await converter2.create(createRecords());
    expect(pdf.length, pdf2.length);
  });

  test('generated data should change on settings change', () async {
    final pdfSettings = PdfExportSettings(
      exportData: true,
      exportStatistics: true,
      exportTitle: true,
    );

    final converter = PdfConverter(
      pdfSettings,
      AppSettings.fromController(testSettingsController!),
      ExportColumnsManager(),
      ExportSettings(),
    );
    final pdf1 = await converter.create(createRecords());

    pdfSettings.exportData = false;
    final pdf2 = await converter.create(createRecords());
    expect(pdf1.length, isNot(pdf2.length));
    expect(pdf1.length, greaterThan(pdf2.length));

    pdfSettings.exportStatistics = false;
    final pdf3 = await converter.create(createRecords());
    expect(pdf3.length, isNot(pdf2.length));
    expect(pdf3.length, isNot(pdf1.length));
    expect(pdf2.length, greaterThan(pdf3.length));

    pdfSettings.exportTitle = false;
    pdfSettings.exportData = true;
    final pdf4 = await converter.create(createRecords());
    expect(pdf4.length, isNot(pdf1.length));
    expect(pdf1.length, greaterThan(pdf4.length));
  });
}
