
import 'package:blood_pressure_app/features/bluetooth/logic/characteristics/ble_measurement_data.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/characteristics/ble_measurement_status.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/measurement_multiple.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_data_store/health_data_store.dart';

import '../../../util.dart';


void main() {
  testWidgets('should show everything and be interactive', (WidgetTester tester) async {
    int tapCount = 0;
    final List<BleMeasurementData> selected = [];
    final measurements = [
      BleMeasurementData(
        systolic: 123,
        diastolic: 456,
        pulse: 67,
        meanArterialPressure: 123456,
        isMMHG: true,
        userID: 3,
        status: BleMeasurementStatus(
          bodyMovementDetected: true,
          cuffTooLose: true,
          irregularPulseDetected: true,
          pulseRateInRange: true,
          pulseRateExceedsUpperLimit: true,
          pulseRateIsLessThenLowerLimit: true,
          improperMeasurementPosition: true,
        ),
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
      BleMeasurementData(
        systolic: 124,
        diastolic: 457,
        pulse: null,
        meanArterialPressure: 123457,
        isMMHG: true,
        userID: null,
        status: BleMeasurementStatus(
          bodyMovementDetected: true,
          cuffTooLose: true,
          irregularPulseDetected: true,
          pulseRateInRange: true,
          pulseRateExceedsUpperLimit: true,
          pulseRateIsLessThenLowerLimit: true,
          improperMeasurementPosition: true,
        ),
        timestamp: null,
      ),
    ];

    await tester.pumpWidget(materialApp(MeasurementMultiple(
      onClosed: () => tapCount++,
      onSelect: selected.add,
      onSelectAll: (_) {},
      measurements: measurements,
    )));

    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(localizations.selectMeasurementTitle), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    expect(find.byType(ListTile), findsNWidgets(2));

    expect(find.textContaining(localizations.userID), findsOneWidget); // one measurement has UserID: null
    expect(find.textContaining(localizations.bloodPressure), findsNWidgets(2));
    for (final measurement in measurements) {
      expect(find.textContaining(measurement.systolic.toInt().toString()), findsOneWidget);
    }

    expect(find.text(localizations.measurementIndex(2)), findsOneWidget);
    expect(find.text(localizations.select), findsNWidgets(2));

    expect(selected, isEmpty);
    await tester.tap(find.text(localizations.select).first);
    expect(selected.length, 1);
    expect(selected, contains(measurements[0]));

    expect(tapCount, 0);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(tapCount, 1);
  });

  testWidgets('imports all measurements when import all is clicked', (WidgetTester tester) async {
    final measurements = [
      BleMeasurementData(
        systolic: 123,
        diastolic: 78,
        meanArterialPressure: 90,
        isMMHG: true,
      ),
      BleMeasurementData(
        systolic: 124,
        diastolic: 79,
        meanArterialPressure: 91,
        isMMHG: true,
      ),
    ];
    List<BleMeasurementData>? importedAll;

    await tester.pumpWidget(materialApp(MeasurementMultiple(
      onClosed: () {},
      onSelect: (_) {},
      onSelectAll: (data) => importedAll = data,
      measurements: measurements,
    )));

    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(localizations.importAll(measurements.length)));
    await tester.pump();

    expect(importedAll, isNotNull);
    expect(importedAll!.length, 2);
    expect(importedAll, containsAll(measurements));
  });

  testWidgets('hides already saved measurements until revealed', (WidgetTester tester) async {
    final time = DateTime(2026, 4, 5, 16, 19, 10);
    final savedReading = BleMeasurementData(
      systolic: 145,
      diastolic: 81,
      meanArterialPressure: 102,
      isMMHG: true,
      pulse: 80,
      timestamp: time,
    );
    final newReading = BleMeasurementData(
      systolic: 127,
      diastolic: 80,
      meanArterialPressure: 95,
      isMMHG: true,
      pulse: 63,
      timestamp: time.add(const Duration(minutes: 1)),
    );

    List<BleMeasurementData>? imported;
    await tester.pumpWidget(materialApp(MeasurementMultiple(
      onClosed: () {},
      onSelect: (_) {},
      onSelectAll: (data) => imported = data,
      measurements: [savedReading, newReading],
      alreadySaved: [
        BloodPressureRecord(
          time: time,
          sys: Pressure.mmHg(145),
          dia: Pressure.mmHg(81),
          pul: 80,
        ),
      ],
    )));
    await tester.pump();

    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    expect(
      find.text('${localizations.newMeasurements(1)} · ${localizations.alreadySavedCount(1)}'),
      findsOneWidget,
    );
    expect(find.textContaining('127/80'), findsOneWidget);
    expect(find.textContaining('145/81'), findsNothing);
    expect(find.text(localizations.importNew(1)), findsOneWidget);

    await tester.tap(find.text(localizations.showAlreadySaved));
    await tester.pump();
    expect(find.textContaining('145/81'), findsOneWidget);
    expect(find.text(localizations.alreadySaved), findsWidgets);

    await tester.tap(find.text(localizations.importNew(1)));
    await tester.pump();
    expect(imported, [newReading]);
  });
}
