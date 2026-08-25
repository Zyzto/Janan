import 'package:blood_pressure_app/features/bluetooth/logic/eufy_body_composition.dart';
import 'package:blood_pressure_app/features/input/add_entry_dialog.dart';
import 'package:blood_pressure_app/features/measurement_list/metric_info_dialog.dart';
import 'package:blood_pressure_app/features/measurement_list/weight_detail_screen.dart';
import 'package:blood_pressure_app/features/settings/body_profile_screen.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/model/body_sex.dart';
import 'package:blood_pressure_app/model/storage/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_data_store/health_data_store.dart';

import '../../util.dart';

void main() {
  final current = BodyweightRecord(
    time: DateTime(2026, 8, 24, 11, 22),
    weight: Weight.kg(100),
    impedanceOhm: 500,
  );
  final previous = BodyweightRecord(
    time: DateTime(2026, 8, 20, 8),
    weight: Weight.kg(102),
    impedanceOhm: 500,
  );
  Settings profile() => Settings(
    bodyHeightCm: 180,
    birthYear: DateTime.now().year - 35,
    bodySex: BodySex.male,
  );

  testWidgets('shows composition when profile and impedance are present', (tester) async {
    await tester.pumpWidget(appBase(
      WeightDetailScreen(record: current),
      settings: profile(),
    ));
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text(localizations.weight), findsWidgets);
    expect(find.text('100 kg'), findsOneWidget);
    expect(find.text(localizations.bodyFat), findsOneWidget);
    expect(find.text(localizations.muscleMass), findsOneWidget);
    expect(find.text(localizations.boneMass), findsOneWidget);
    expect(find.text(localizations.bodyWater), findsOneWidget);
    expect(find.text(localizations.bmi), findsOneWidget);
    await tester.scrollUntilVisible(find.text(localizations.bmr), 200);
    expect(find.text(localizations.leanBodyMass), findsOneWidget);
    expect(find.text(localizations.bmr), findsOneWidget);
    expect(find.text(localizations.bodyCompositionEstimated), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsNothing);
    expect(find.byIcon(Icons.arrow_downward), findsNothing);
  });

  testWidgets('compares against a heavier previous weigh-in', (tester) async {
    await tester.pumpWidget(appBase(
      WeightDetailScreen(record: current, previous: previous),
      settings: profile(),
    ));
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text(localizations.comparedToPrevious), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward), findsWidgets);
  });

  testWidgets('prompts for a profile when impedance is present without one', (tester) async {
    await tester.pumpWidget(appBase(
      WeightDetailScreen(record: current),
    ));
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text(localizations.bodyFat), findsNothing);
    expect(find.text(localizations.bodyProfileIncomplete), findsOneWidget);

    await tester.tap(find.text(localizations.bodyProfileIncomplete));
    await tester.pumpAndSettle();
    expect(find.byType(BodyProfileScreen), findsOneWidget);
  });

  testWidgets('tapping body fat opens the metric card with a highlighted range', (tester) async {
    final settings = profile();
    final composition = EufyBodyComposition.fromRecord(current, settings)!;
    final hero = '${composition.bodyFatPercent.toStringAsFixed(1)} %';
    await tester.pumpWidget(appBase(
      WeightDetailScreen(record: current),
      settings: settings,
    ));
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(localizations.bodyFat));
    await tester.pumpAndSettle();

    expect(find.byType(MetricInfoDialog), findsOneWidget);
    expect(find.text(hero), findsWidgets);
    expect(find.text(localizations.metricRangeHigh), findsWidgets);
    expect(find.text('> 20 %'), findsOneWidget);
    expect(find.text(localizations.warnAboutTxt1), findsNothing);
    expect(
      tester.widgetList<Text>(find.text(localizations.metricRangeHigh))
          .any((text) => text.style?.fontWeight == FontWeight.w600),
      isTrue,
    );
  });

  testWidgets('opens the edit form', (tester) async {
    await tester.pumpWidget(appBase(
      WeightDetailScreen(record: current),
      settings: Settings(weightInput: true),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(AddEntryDialog), findsOneWidget);
  });

  testWidgets('deletes after confirmation', (tester) async {
    final repo = MockBodyweightRepository();
    await repo.add(current);
    await tester.pumpWidget(appBase(
      WeightDetailScreen(record: current),
      weightRepo: repo,
    ));
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(localizations.btnConfirm));
    await tester.pumpAndSettle();

    expect(repo.data, isEmpty);
  });
}
