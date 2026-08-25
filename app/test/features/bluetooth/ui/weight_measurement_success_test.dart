import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_weight_data.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/weight_measurement_success.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../util.dart';

void main() {
  testWidgets('shows kilograms and ohms', (tester) async {
    await tester.pumpWidget(materialApp(
      WeightMeasurementSuccess(
        onTap: () {},
        data: BleWeightData(
          kg: 102.3,
          time: DateTime(2026, 8, 24, 8, 9),
          impedance: 500,
        ),
      ),
    ));
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(localizations.weight), findsOneWidget);
    expect(find.text('102.3 kg'), findsOneWidget);
    expect(find.text(localizations.impedance), findsOneWidget);
    expect(find.text('500.0 Ω'), findsOneWidget);
  });

  testWidgets('hides ohms when the scale sent none', (tester) async {
    await tester.pumpWidget(materialApp(
      WeightMeasurementSuccess(
        onTap: () {},
        data: BleWeightData(kg: 102.3, time: DateTime(2026, 8, 24)),
      ),
    ));
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(localizations.weight), findsOneWidget);
    expect(find.text(localizations.impedance), findsNothing);
  });
}
