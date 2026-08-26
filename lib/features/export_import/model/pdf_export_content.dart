import 'package:blood_pressure_app/domain/domain.dart';
import 'package:blood_pressure_app/features/export_import/model/column.dart';
import 'package:blood_pressure_app/features/export_import/model/import_field_type.dart';
import 'package:blood_pressure_app/features/statistics/dashboard/dashboard_snapshot.dart';
import 'package:blood_pressure_app/l10n/western_digits.dart';
import 'package:blood_pressure_app/model/blood_pressure/pressure_unit.dart';
import 'package:blood_pressure_app/model/blood_pressure_analyzer.dart';
import 'package:blood_pressure_app/model/combined_entry.dart';
import 'package:blood_pressure_app/model/weight_unit.dart';
import 'package:easy_localization/easy_localization.dart';

/// Placeholder used in PDF cells when a value is missing.
///
/// ASCII hyphen so the default PDF fonts can draw it.
const pdfMissingValue = '-';

/// Newest blood-pressure reading shown above the PDF table.
class PdfExportLatestReading {
  /// Create a formatted latest-reading line.
  const PdfExportLatestReading({
    required this.time,
    required this.sys,
    required this.dia,
    required this.pul,
  });

  /// Timestamp in the user's date format.
  final String time;

  /// Systolic in the preferred unit, or [pdfMissingValue].
  final String sys;

  /// Diastolic in the preferred unit, or [pdfMissingValue].
  final String dia;

  /// Pulse in bpm, or [pdfMissingValue].
  final String pul;
}

/// Dashboard-matching statistics for the exported range.
class PdfExportStatistics {
  /// Create the stats block model.
  const PdfExportStatistics({
    required this.count,
    required this.measurementsPerDay,
    required this.unitLabel,
    required this.activityLine,
    required this.latest,
    required this.table,
  });

  /// Blood-pressure records in the exported range.
  final int count;

  /// Average measurements per day, when the analyzer can compute it.
  final int? measurementsPerDay;

  /// Localized preferred pressure unit.
  final String unitLabel;

  /// Count / per-day sentence matching the dashboard.
  final String activityLine;

  /// Newest blood-pressure row, when one exists.
  final PdfExportLatestReading? latest;

  /// Header plus average / maximum / minimum rows.
  final List<List<String>> table;
}

/// Testable strings and table cells for a PDF export.
class PdfExportContent {
  /// Create content that the PDF converter can lay out.
  const PdfExportContent({
    required this.title,
    required this.statistics,
    required this.headers,
    required this.rows,
  });

  /// Build PDF strings from already-filtered, oldest-first [entries].
  factory PdfExportContent.from({
    required List<CombinedEntry> entries,
    required String dateFormatString,
    required PressureUnit pressureUnit,
    required WeightUnit weightUnit,
    required List<ExportColumn> columns,
  }) {
    final newestFirst = entries.reversed.toList();
    final snapshot = DashboardSnapshot.from(entriesNewestFirst: newestFirst);
    final analyzer = snapshot.period;
    final dateFormatter = WesternDateFormat(dateFormatString, Intl.defaultLocale);

    return PdfExportContent(
      title: _title(entries, analyzer, dateFormatter),
      statistics: _statistics(snapshot, pressureUnit, dateFormatter),
      headers: columns.map((column) => column.userTitle()).toList(),
      rows: [
        for (final entry in entries)
          [
            for (final column in columns)
              _cell(entry, column, pressureUnit, weightUnit),
          ],
      ],
    );
  }

  /// Date-range headline, or a no-data message.
  final String title;

  /// Stats shown above the table.
  final PdfExportStatistics statistics;

  /// Localized column titles.
  final List<String> headers;

  /// One row per exported entry, oldest first.
  final List<List<String>> rows;
}

String _title(
  List<CombinedEntry> entries,
  BloodPressureAnalyzer analyzer,
  DateFormat dateFormatter,
) {
  final start = analyzer.firstDay ?? (entries.isEmpty ? null : entries.first.time);
  final end = analyzer.lastDay ?? (entries.isEmpty ? null : entries.last.time);
  if (start == null || end == null) return 'errNoData'.tr();
  return 'pdfDocumentTitle'.tr(namedArgs: {
    'start': dateFormatter.format(start),
    'end': dateFormatter.format(end),
  });
}

PdfExportStatistics _statistics(
  DashboardSnapshot snapshot,
  PressureUnit pressureUnit,
  DateFormat dateFormatter,
) {
  final period = snapshot.period;
  final activityLine = snapshot.measurementsPerDay == null
      ? 'dashboardActivityCount'.tr(namedArgs: {
          'count': snapshot.count.toString(),
        })
      : 'dashboardActivityLine'.tr(namedArgs: {
          'count': snapshot.count.toString(),
          'perDay': snapshot.measurementsPerDay.toString(),
        });
  final latestEntry = snapshot.latest;
  return PdfExportStatistics(
    count: snapshot.count,
    measurementsPerDay: snapshot.measurementsPerDay,
    unitLabel: _pressureUnitLabel(pressureUnit),
    activityLine: activityLine,
    latest: latestEntry == null
        ? null
        : PdfExportLatestReading(
            time: dateFormatter.format(latestEntry.time),
            sys: _pdfPressure(latestEntry.sys, pressureUnit),
            dia: _pdfPressure(latestEntry.dia, pressureUnit),
            pul: _pdfNumber(latestEntry.pul?.toDouble()),
          ),
    table: [
      [
        '',
        'sysLong'.tr(),
        'diaLong'.tr(),
        'pulLong'.tr(),
      ],
      [
        'average'.tr(),
        _pdfPressure(period.avgSys, pressureUnit),
        _pdfPressure(period.avgDia, pressureUnit),
        _pdfNumber(period.avgPul?.toDouble()),
      ],
      [
        'maximum'.tr(),
        _pdfPressure(period.maxSys, pressureUnit),
        _pdfPressure(period.maxDia, pressureUnit),
        _pdfNumber(period.maxPul?.toDouble()),
      ],
      [
        'minimum'.tr(),
        _pdfPressure(period.minSys, pressureUnit),
        _pdfPressure(period.minDia, pressureUnit),
        _pdfNumber(period.minPul?.toDouble()),
      ],
    ],
  );
}

String _cell(
  CombinedEntry entry,
  ExportColumn column,
  PressureUnit pressureUnit,
  WeightUnit weightUnit,
) {
  switch (column.restoreAbleType) {
    case RowDataFieldType.sys:
      return _pdfPressure(entry.sys, pressureUnit);
    case RowDataFieldType.dia:
      return _pdfPressure(entry.dia, pressureUnit);
    case RowDataFieldType.pul:
      return _pdfNumber(entry.pul?.toDouble());
    case RowDataFieldType.weightKg:
      final weight = entry.weight?.weight;
      return weight == null ? pdfMissingValue : weightUnit.format(weight);
    case RowDataFieldType.intakes:
      if (entry.intake == null) return pdfMissingValue;
      return column.encode(entry);
    case RowDataFieldType.timestamp:
    case RowDataFieldType.notes:
    case RowDataFieldType.color:
    case null:
      final encoded = column.encode(entry);
      if (encoded.isEmpty || encoded == 'null') return pdfMissingValue;
      return encoded;
  }
}

String _pdfPressure(Pressure? pressure, PressureUnit unit) {
  final text = formatDashboardPressure(pressure, unit);
  return text == '—' ? pdfMissingValue : text;
}

String _pdfNumber(double? value) {
  final text = formatDashboardNumber(value, digits: 0);
  return text == '—' ? pdfMissingValue : text;
}

String _pressureUnitLabel(PressureUnit unit) => switch (unit) {
  PressureUnit.mmHg => 'pressureUnitMmHg'.tr(),
  PressureUnit.kPa => 'pressureUnitKPa'.tr(),
};
