import 'package:blood_pressure_app/features/settings/bluetooth_devices_screen.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/model/known_ble_device.dart';
import 'package:blood_pressure_app/model/storage/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  testWidgets('shows empty state', (tester) async {
    await tester.pumpWidget(materialApp(const BluetoothDevicesScreen()));
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(localizations.noBluetoothDevices), findsOneWidget);
    expect(find.text(localizations.addBluetoothDevice), findsOneWidget);
  });

  testWidgets('lists remembered devices', (tester) async {
    await tester.pumpWidget(materialApp(
      const BluetoothDevicesScreen(),
      settings: Settings(knownBleDev: const [
        KnownBleDevice(id: 'abc', name: 'X4 Smart'),
        KnownBleDevice(id: 'def', name: 'BM 59'),
      ]),
    ));

    expect(find.text('X4 Smart'), findsOneWidget);
    expect(find.text('abc'), findsOneWidget);
    expect(find.text('BM 59'), findsOneWidget);
    expect(find.text('def'), findsOneWidget);
  });

  testWidgets('forgets a device after confirmation', (tester) async {
    final settings = Settings(knownBleDev: const [
      KnownBleDevice(id: 'abc', name: 'X4 Smart'),
    ]);
    await tester.pumpWidget(materialApp(
      const BluetoothDevicesScreen(),
      settings: settings,
    ));

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(localizations.btnConfirm));
    await tester.pumpAndSettle();

    expect(settings.knownBleDev, isEmpty);
    expect(find.text(localizations.noBluetoothDevices), findsOneWidget);
  });

  testWidgets('toggles auto-sync for a device', (tester) async {
    final settings = Settings(knownBleDev: const [
      KnownBleDevice(id: 'abc', name: 'X4 Smart'),
    ]);
    await tester.pumpWidget(materialApp(
      const BluetoothDevicesScreen(),
      settings: settings,
    ));

    expect(settings.knownBleDev.single.autoSync, isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(settings.knownBleDev.single.id, 'abc');
    expect(settings.knownBleDev.single.autoSync, isFalse);
  });
}
