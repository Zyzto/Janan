import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_weight_data.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/weight_measurement_success.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/model/body_sex.dart';
import 'package:blood_pressure_app/model/storage/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../util.dart';

void main() {
  final data = BleWeightData(
    kg: 102.3,
    time: DateTime(2026, 8, 24, 8, 9),
    impedance: 500,
  );

  testWidgets('shows composition when profile and impedance are present', (tester) async {
    await tester.pumpWidget(materialApp(
      WeightMeasurementSuccess(onTap: () {}, data: data),
      settings: Settings(
        bodyHeightCm: 180,
        birthYear: DateTime.now().year - 35,
        bodySex: BodySex.male,
      ),
    ));
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(localizations.bodyFat), findsOneWidget);
    expect(find.text(localizations.muscleMass), findsOneWidget);
    expect(find.text(localizations.boneMass), findsOneWidget);
    expect(find.text(localizations.bodyWater), findsOneWidget);
    expect(find.text(localizations.leanBodyMass), findsOneWidget);
    expect(find.text(localizations.bmr), findsOneWidget);
    expect(find.text(localizations.bodyCompositionEstimated), findsOneWidget);
    expect(find.text(localizations.bodyProfileIncomplete), findsNothing);
  });

  testWidgets('prompts for a profile when impedance is present without one', (tester) async {
    await tester.pumpWidget(materialApp(
      WeightMeasurementSuccess(onTap: () {}, data: data),
    ));
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(localizations.bodyFat), findsNothing);
    expect(find.text(localizations.bodyProfileIncomplete), findsOneWidget);
  });

  testWidgets('hides composition when the scale sent no impedance', (tester) async {
    await tester.pumpWidget(materialApp(
      WeightMeasurementSuccess(
        onTap: () {},
        data: BleWeightData(kg: 102.3, time: DateTime(2026, 8, 24)),
      ),
      settings: Settings(
        bodyHeightCm: 180,
        birthYear: 1990,
        bodySex: BodySex.male,
      ),
    ));
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(localizations.bodyFat), findsNothing);
    expect(find.text(localizations.bodyProfileIncomplete), findsNothing);
    expect(find.text(localizations.weight), findsOneWidget);
  });
}
