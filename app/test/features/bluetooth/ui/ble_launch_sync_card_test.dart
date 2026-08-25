import 'package:blood_pressure_app/features/bluetooth/logic/ble_launch_sync.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/ble_launch_sync_card.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../util.dart';

void main() {
  testWidgets('shows looking progress before a meter is found', (tester) async {
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(materialApp(const BleLaunchSyncCard(
      progress: BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.scanning,
        deviceName: 'BM59',
      ),
    )));

    expect(find.text(localizations.lookingForDevice('BM59')), findsOneWidget);
    expect(find.text(localizations.checkingForOneMinute), findsOneWidget);
    expect(find.text(localizations.syncStepLook), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
  });

  testWidgets('offers pause while a sync is running', (tester) async {
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    var paused = false;
    await tester.pumpWidget(materialApp(BleLaunchSyncCard(
      progress: const BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.scanning,
        deviceName: 'BM59',
      ),
      onPause: () => paused = true,
    )));

    expect(find.byTooltip(localizations.pauseMeterSync), findsOneWidget);
    expect(find.text(localizations.pauseMeterSync), findsNothing);
    await tester.tap(find.byIcon(Icons.pause));
    expect(paused, isTrue);
  });

  testWidgets('offers resume when sync is paused', (tester) async {
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    var resumed = false;
    await tester.pumpWidget(materialApp(BleLaunchSyncCard(
      progress: const BleLaunchSyncProgress(deviceName: 'BM59'),
      paused: true,
      onResume: () => resumed = true,
    )));

    expect(find.text(localizations.meterSyncPaused), findsOneWidget);
    expect(find.text(localizations.meterSyncPausedHint), findsOneWidget);
    expect(find.byTooltip(localizations.resumeMeterSync), findsOneWidget);
    expect(find.text(localizations.resumeMeterSync), findsNothing);
    expect(find.byIcon(Icons.pause), findsNothing);
    await tester.tap(find.byIcon(Icons.play_arrow));
    expect(resumed, isTrue);
  });

  testWidgets('offers resume when the meter was not found', (tester) async {
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    var resumed = false;
    await tester.pumpWidget(materialApp(BleLaunchSyncCard(
      progress: const BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.done,
        result: BleLaunchSyncResult(status: BleLaunchSyncStatus.notFound),
      ),
      onResume: () => resumed = true,
    )));

    expect(find.text(localizations.meterNotFound), findsOneWidget);
    expect(find.byTooltip(localizations.resumeMeterSync), findsOneWidget);
    expect(find.text(localizations.resumeMeterSync), findsNothing);
    await tester.tap(find.byIcon(Icons.play_arrow));
    expect(resumed, isTrue);
  });

  testWidgets('shows found meter and connect info', (tester) async {
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(materialApp(const BleLaunchSyncCard(
      progress: BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.connecting,
        deviceName: 'BM59',
      ),
    )));

    expect(find.text(localizations.foundMeterNamed('BM59')), findsOneWidget);
    expect(find.text(localizations.connectingToDevice('BM59')), findsOneWidget);
    expect(find.text(localizations.waitForMeterMeasurement), findsOneWidget);
    expect(find.text(localizations.syncStepConnect), findsOneWidget);
  });

  testWidgets('keeps the connect stage while looking for extra devices', (tester) async {
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(materialApp(const BleLaunchSyncCard(
      progress: BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.reading,
        deviceName: 'BM59',
        lookingForMore: true,
      ),
    )));

    expect(find.text(localizations.readingStoredMeasurements), findsOneWidget);
    expect(find.text(localizations.scanningForExtraDevices), findsOneWidget);
    expect(find.text(localizations.syncStepRead), findsOneWidget);
    expect(find.text(localizations.checkingForOneMinute), findsNothing);
  });

  testWidgets('shows reading progress after the connection is open', (tester) async {
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(materialApp(const BleLaunchSyncCard(
      progress: BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.reading,
        deviceName: 'BM59',
      ),
    )));

    expect(find.text(localizations.readingStoredMeasurements), findsWidgets);
    expect(find.text(localizations.waitForMeterMeasurement), findsOneWidget);
    expect(find.text(localizations.syncStepRead), findsOneWidget);
  });

  testWidgets('shows imported count and skipped duplicates', (tester) async {
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(materialApp(const BleLaunchSyncCard(
      progress: BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.done,
        deviceName: 'BM59',
        receivedCount: 12,
        result: BleLaunchSyncResult(
          status: BleLaunchSyncStatus.imported,
          count: 3,
          receivedCount: 12,
          deviceName: 'BM59',
        ),
      ),
    )));

    expect(find.text(localizations.importedNewMeasurements(3)), findsOneWidget);
    expect(find.text(localizations.skippedAlreadySaved(9)), findsOneWidget);
  });
}
