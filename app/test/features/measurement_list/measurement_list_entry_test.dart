import 'package:blood_pressure_app/features/measurement_list/measurement_detail_screen.dart';
import 'package:blood_pressure_app/features/measurement_list/measurement_list_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_data_store/health_data_store.dart';

import '../../model/export_import/record_formatter_test.dart';
import '../../util.dart';

void main() {
  testWidgets('should initialize without errors', (tester) async {
    await tester.pumpWidget(materialApp(MeasurementListRow(
      data: mockEntryPos(DateTime(2023), 123, 80, 60, 'test'),),),);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(materialApp(MeasurementListRow(
      data: mockEntryPos(DateTime.fromMillisecondsSinceEpoch(31279811), null, null, null, 'null test'),),),);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(materialApp(MeasurementListRow(
      data: mockEntryPos(DateTime(2023), 124, 85, 63, 'color',Colors.cyan))));
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens details instead of expanding', (tester) async {
    await tester.pumpWidget(appBase(MeasurementListRow(
      data: mockEntryPos(DateTime(2023), 123, 78, 56),
    )));
    expect(find.byIcon(Icons.expand_more), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);

    await tester.tap(find.text('123'));
    await tester.pumpAndSettle();

    expect(find.byType(MeasurementDetailScreen), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  testWidgets('should display correct information', (tester) async {
    await tester.pumpWidget(materialApp(MeasurementListRow(
        data: mockEntryPos(DateTime(2023), 123, 78, 56, 'Test text'),),),);
    expect(find.text('123'), findsOneWidget);
    expect(find.text('78'), findsOneWidget);
    expect(find.text('56'), findsOneWidget);
    expect(find.textContaining('2023'), findsNothing);
    expect(find.text('Test text'), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('should not display null values', (tester) async {
    await tester.pumpWidget(materialApp(MeasurementListRow(
      data: mockEntry(time: DateTime(2023)),),),);
    expect(find.text('null'), findsNothing);
    expect(find.byIcon(Icons.medication), findsNothing);
  });

  testWidgets('should indicate presence of intakes', (tester) async {
    await tester.pumpWidget(materialApp(MeasurementListRow(
      data: mockEntry(
        time: DateTime(2023),
        intake: (mockMedicine(designation: 'testMed', color: Colors.red), 12.0),
      ),
    ),),);
    expect(find.byIcon(Icons.medication), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is Icon
      && widget.icon == Icons.medication
      && widget.color?.toARGB32() == Colors.red.toARGB32()), findsNothing);
  });
}

MedicineIntake mockIntake(Medicine medicine, {
  int? time,
  double? dosis,
}) => MedicineIntake(
  time: time!=null ? DateTime.fromMillisecondsSinceEpoch(time) : DateTime.now(),
  medicine: medicine,
  dosis: Weight.mg(dosis ?? medicine.dosis?.mg ?? 42.0),
);
