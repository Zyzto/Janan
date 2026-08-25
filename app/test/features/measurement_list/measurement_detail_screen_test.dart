import 'package:blood_pressure_app/features/input/add_entry_dialog.dart';
import 'package:blood_pressure_app/features/measurement_list/measurement_detail_screen.dart';
import 'package:blood_pressure_app/features/measurement_list/metric_info_dialog.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/model/storage/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../model/export_import/record_formatter_test.dart';
import '../../util.dart';

void main() {
  testWidgets('shows sys dia pul note and medicine', (tester) async {
    final entry = mockEntry(
      time: DateTime(2026, 8, 24, 8, 15),
      sys: 120,
      dia: 80,
      pul: 70,
      note: 'after walk',
      intake: (mockMedicine(designation: 'testMed', color: Colors.red), 12.0),
    );
    await tester.pumpWidget(appBase(
      MeasurementDetailScreen(entry: entry),
    ));
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text(localizations.sysLong), findsOneWidget);
    expect(find.text(localizations.diaLong), findsOneWidget);
    expect(find.text(localizations.pulLong), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('80'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
    expect(find.text('after walk'), findsOneWidget);
    expect(find.text('testMed'), findsOneWidget);
    expect(find.text('12.0mg'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsNothing);
    expect(find.byIcon(Icons.arrow_downward), findsNothing);
  });

  testWidgets('compares against a higher previous reading', (tester) async {
    final current = mockEntry(time: DateTime(2026, 8, 24), sys: 120, dia: 80, pul: 70);
    final previous = mockEntry(time: DateTime(2026, 8, 20), sys: 130, dia: 85, pul: 75);
    await tester.pumpWidget(appBase(
      MeasurementDetailScreen(entry: current, previous: previous),
    ));
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text(localizations.comparedToPrevious), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward), findsNWidgets(3));
  });

  testWidgets('tapping systolic opens the metric card with a highlighted range', (tester) async {
    await tester.pumpWidget(appBase(
      MeasurementDetailScreen(
        entry: mockEntry(time: DateTime(2026, 8, 24), sys: 120, dia: 80, pul: 70),
      ),
      settings: Settings(sysWarn: 135),
    ));
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(localizations.sysLong));
    await tester.pumpAndSettle();

    expect(find.byType(MetricInfoDialog), findsOneWidget);
    expect(find.text('120'), findsWidgets);
    expect(find.text(localizations.metricRangeElevated), findsWidgets);
    expect(find.text(localizations.metricWarnAt('135')), findsOneWidget);
    expect(find.text(localizations.warnAboutTxt1), findsOneWidget);
    expect(
      tester.widgetList<Text>(find.text(localizations.metricRangeElevated))
          .any((text) => text.style?.fontWeight == FontWeight.w600),
      isTrue,
    );
    final barBoxes = tester.renderObjectList<RenderBox>(
      find.descendant(
        of: find.byType(MetricInfoDialog),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(barBoxes, isNotEmpty);
    expect(barBoxes.every((box) => box.size.height == 8), isTrue);
    expect(barBoxes.fold<double>(0, (sum, box) => sum + box.size.width), greaterThan(100));
  });

  testWidgets('opens the edit form', (tester) async {
    await tester.pumpWidget(appBase(
      MeasurementDetailScreen(
        entry: mockEntry(time: DateTime(2026, 8, 24), sys: 120, dia: 80, pul: 70),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(AddEntryDialog), findsOneWidget);
  });

  testWidgets('deletes using confirmDeletion', (tester) async {
    final entry = mockEntry(time: DateTime(2026, 8, 24), sys: 120, dia: 80);
    final bpRepo = MockBloodPressureRepository();
    await bpRepo.add(entry.record!);
    await tester.pumpWidget(appBase(
      MeasurementDetailScreen(entry: entry),
      bpRepo: bpRepo,
      settings: Settings(confirmDeletion: false),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(bpRepo.data, isEmpty);
  });
}
