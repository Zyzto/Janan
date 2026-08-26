import 'dart:typed_data';
import 'dart:ui';

import 'package:blood_pressure_app/features/export_import/model/export_preset.dart';
import 'package:blood_pressure_app/features/export_import/model/pdf_export_content.dart';
import 'package:blood_pressure_app/features/settings/app_settings.dart';
import 'package:blood_pressure_app/logging.dart';
import 'package:blood_pressure_app/model/combined_entry.dart';
import 'package:blood_pressure_app/model/storage/export_columns_store.dart';
import 'package:blood_pressure_app/model/storage/export_pdf_settings.dart';
import 'package:blood_pressure_app/model/storage/export_settings.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Utility class for creating pdf files.
class PdfConverter with Loggable {
  /// Create pdf builder.
  PdfConverter(this.pdfSettings, this.settings, this.availableColumns, this.exportSettings);

  /// pdf specific settings.
  final PdfExportSettings pdfSettings;

  /// General customised design information that can be applied to the Pdf.
  final AppSettings settings;

  /// Columns manager used for ex- and import.
  final ExportColumnsManager availableColumns;

  final ExportSettings exportSettings;

  /// Create a pdf from a record list.
  Future<Uint8List> create(List<CombinedEntry> entries) async {
    final pdf = pw.Document(
      creator: 'Janan',
    );
    final content = _content(entries);
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => [
        if (pdfSettings.exportTitle)
          _buildPdfTitle(content.title),
        if (pdfSettings.exportStatistics)
          _buildPdfStatistics(content.statistics),
        if (pdfSettings.exportData)
          _buildPdfTable(content),
      ],
      maxPages: 100,
    ),);
    return pdf.save();
  }

  /// Strings and cells laid out by [create].
  PdfExportContent _content(List<CombinedEntry> entries) {
    final preset = exportSettings.getPresetById(pdfSettings.activePreset);
    if (preset == null) {
      logSevere('No such preset: ${pdfSettings.activePreset}');
    }
    final columns = availableColumns.resolveColumns(preset?.columns ?? []);
    return PdfExportContent.from(
      entries: entries,
      dateFormatString: settings.dateFormatString,
      pressureUnit: settings.preferredPressureUnit,
      weightUnit: settings.weightUnit,
      columns: columns,
    );
  }

  pw.Widget _buildPdfTitle(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(
      title,
      style: const pw.TextStyle(fontSize: 16),
    ),
  );

  pw.Widget _buildPdfStatistics(PdfExportStatistics statistics) =>
    pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            statistics.activityLine,
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'pdfExportUnit'.tr(namedArgs: {
              'unit': statistics.unitLabel,
            }),
            style: const pw.TextStyle(fontSize: 10),
          ),
          if (statistics.latest != null) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'pdfLatestReading'.tr(namedArgs: {
                'sys': statistics.latest!.sys,
                'dia': statistics.latest!.dia,
                'pul': statistics.latest!.pul,
                'time': statistics.latest!.time,
              }),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
          pw.SizedBox(height: 10),
          pw.Text(
            'dashboardAverages'.tr(),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            border: null,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            data: statistics.table,
          ),
        ],
      ),
    );

  pw.Widget _buildPdfTable(PdfExportContent content) =>
    pw.TableHelper.fromTextArray(
      border: null,
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide()),
      ),
      headerHeight: pdfSettings.headerHeight,
      cellHeight: pdfSettings.cellHeight,
      cellAlignments: {
        for (final v in List.generate(content.headers.length, (idx) => idx))
          v: pw.Alignment.centerLeft,
      },
      headerStyle: pw.TextStyle(
        color: PdfColors.black,
        fontSize: pdfSettings.headerFontSize,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(
        fontSize: pdfSettings.cellFontSize,
      ),
      headerCellDecoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: settings.accentColor.toPdfColor(),
            width: 5,
          ),
        ),
      ),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.blueGrey,
            width: .5,
          ),
        ),
      ),
      headers: content.headers,
      data: content.rows,
    );
}

extension _PdfCompatability on Color {
  PdfColor toPdfColor() => PdfColor(r / 256, g / 256, b / 256, a);
}
