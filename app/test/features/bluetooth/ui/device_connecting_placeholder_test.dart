import 'package:blood_pressure_app/features/bluetooth/ui/device_connecting_placeholder.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../util.dart';

void main() {
  testWidgets('shows a named connecting state', (WidgetTester tester) async {
    await tester.pumpWidget(materialApp(
      const DeviceConnectingPlaceholder(deviceName: 'X4 Smart'),
    ));

    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(localizations.connectingToDevice('X4 Smart')), findsOneWidget);
    expect(find.text(localizations.readingMeasurement), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('falls back when the meter name is unknown', (WidgetTester tester) async {
    await tester.pumpWidget(materialApp(
      const DeviceConnectingPlaceholder(),
    ));

    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(localizations.connectingToMeter), findsOneWidget);
    expect(find.text(localizations.readingMeasurement), findsOneWidget);
  });
}
