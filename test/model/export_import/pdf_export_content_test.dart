import 'package:blood_pressure_app/features/export_import/model/export_preset.dart';
import 'package:blood_pressure_app/features/export_import/model/pdf_export_content.dart';
import 'package:blood_pressure_app/features/statistics/dashboard/dashboard_snapshot.dart';
import 'package:blood_pressure_app/model/blood_pressure/pressure_unit.dart';
import 'package:blood_pressure_app/model/combined_entry.dart';
import 'package:blood_pressure_app/model/storage/export_columns_store.dart';
import 'package:blood_pressure_app/model/weight_unit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blood_pressure_app/domain/domain.dart';

import 'record_formatter_test.dart';

void main() {
  final columns = ExportColumnsManager().resolveColumns(ExportPreset.appPdf.columns);

  PdfExportContent contentOf(
    List<CombinedEntry> entries, {
    PressureUnit unit = PressureUnit.mmHg,
    WeightUnit weightUnit = WeightUnit.kg,
  }) => PdfExportContent.from(
    entries: entries,
    dateFormatString: 'yyyy-MM-dd',
    pressureUnit: unit,
    weightUnit: weightUnit,
    columns: columns,
  );

  test('builds one table row per entry in oldest-first order', () {
    final early = mockEntry(
      time: DateTime(2024, 1, 1, 8),
      sys: 120,
      dia: 80,
      pul: 70,
      note: 'morning',
    );
    final late = mockEntry(
      time: DateTime(2024, 1, 3, 20),
      sys: 130,
      dia: 85,
      pul: 72,
      note: 'evening',
    );
    final content = contentOf([early, late]);

    expect(content.rows, hasLength(2));
    expect(content.rows.first[1], '120');
    expect(content.rows.last[1], '130');
    expect(content.rows.first[4], 'morning');
    expect(content.statistics.count, 2);
  });

  test('formats pressures in the preferred unit', () {
    final entry = mockEntry(
      time: DateTime(2024, 2, 1),
      sys: 120,
      dia: 80,
      pul: 70,
    );
    final mmHg = contentOf([entry]);
    final kPa = contentOf([entry], unit: PressureUnit.kPa);

    expect(mmHg.rows.single[1], '120');
    expect(mmHg.rows.single[2], '80');
    expect(mmHg.statistics.table[1][1], '120');
    expect(kPa.rows.single[1], isNot('120'));
    expect(kPa.rows.single[1], formatDashboardPressure(entry.sys, PressureUnit.kPa));
    expect(kPa.statistics.table[1][1], kPa.rows.single[1]);
  });

  test('uses dashboard avg min max and latest reading', () {
    final older = mockEntry(
      time: DateTime(2024, 3, 1, 8),
      sys: 100,
      dia: 60,
      pul: 60,
    );
    final newer = mockEntry(
      time: DateTime(2024, 3, 3, 18),
      sys: 140,
      dia: 90,
      pul: 80,
    );
    final content = contentOf([older, newer]);

    expect(content.statistics.table[1], ['average', '120', '75', '70']);
    expect(content.statistics.table[2], ['maximum', '140', '90', '80']);
    expect(content.statistics.table[3], ['minimum', '100', '60', '60']);
    expect(content.statistics.latest, isNotNull);
    expect(content.statistics.latest!.sys, '140');
    expect(content.statistics.latest!.dia, '90');
    expect(content.statistics.latest!.pul, '80');
    expect(content.statistics.latest!.time, '2024-03-03');
    expect(content.statistics.measurementsPerDay, 1);
  });

  test('renders missing pressure weight and intakes as a dash', () {
    final time = DateTime(2024, 4, 1);
    final entry = CombinedEntry(
      time: time,
      record: BloodPressureRecord(time: time),
      note: Note(time: time),
    );
    final content = contentOf([entry]);

    expect(content.rows.single[1], pdfMissingValue);
    expect(content.rows.single[2], pdfMissingValue);
    expect(content.rows.single[3], pdfMissingValue);
    expect(content.rows.single[4], pdfMissingValue);
    expect(content.rows.single[5], pdfMissingValue);
    expect(content.rows.single[6], pdfMissingValue);
    expect(content.rows.single, isNot(contains('null')));
  });

  test('includes notes weight and intakes in the PDF preset', () {
    final time = DateTime(2024, 5, 1, 9);
    final entry = CombinedEntry(
      time: time,
      record: BloodPressureRecord(
        time: time,
        sys: Pressure.mmHg(118),
        dia: Pressure.mmHg(76),
        pul: 64,
      ),
      note: Note(time: time, note: 'after walk'),
      weight: BodyweightRecord(time: time, weight: Weight.kg(70.5)),
      intake: MedicineIntake(
        time: time,
        medicine: const Medicine(designation: 'Lisinopril'),
        dosis: Weight.mg(10),
      ),
    );
    final content = contentOf([entry]);

    expect(content.headers, hasLength(7));
    expect(content.rows.single[4], 'after walk');
    expect(content.rows.single[5], contains('70.5'));
    expect(content.rows.single[6], contains('Lisinopril'));
    expect(content.rows.single[6], contains('10'));
  });
}
