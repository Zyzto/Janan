import 'package:blood_pressure_app/features/bluetooth/logic/ble_launch_sync.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/ble_launch_sync_card.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/ble_launch_sync_host.dart';
import 'package:blood_pressure_app/features/home/ble_home_sync_indicator.dart';
import 'package:blood_pressure_app/model/bluetooth_input_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

TestSettingsSeed _enabledSettings() => TestSettingsSeed(
  syncBluetoothOnLaunch: true,
  bleInput: BluetoothInputMode.newBluetoothInputCrossPlatform,
);

Future<Widget> _indicator(BleLaunchSyncView view, {TestSettingsSeed? settings}) => materialApp(
  BleLaunchSyncScope(
    notifier: view,
    child: Scaffold(
      appBar: AppBar(actions: const [BleHomeSyncIndicator()]),
      body: const BleLaunchSyncPopout(),
    ),
  ),
  settings: settings ?? _enabledSettings(),
);

void main() {
  testWidgets('hides when launch sync is turned off', (tester) async {
    final view = BleLaunchSyncView()
      ..setProgress(const BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.scanning,
        deviceName: 'BM59',
      ));
    await tester.pumpWidget(await materialApp(
      BleLaunchSyncScope(
        notifier: view,
        child: Scaffold(
          appBar: AppBar(actions: const [BleHomeSyncIndicator()]),
        ),
      ),
      settings: TestSettingsSeed(
        syncBluetoothOnLaunch: false,
        bleInput: BluetoothInputMode.newBluetoothInputCrossPlatform,
      ),
    ));

    expect(find.byIcon(Icons.sync), findsNothing);
    expect(find.byIcon(Icons.bluetooth), findsNothing);
  });

  testWidgets('hides when no meter search is running', (tester) async {
    await tester.pumpWidget(await materialApp(Scaffold(
      appBar: AppBar(actions: const [BleHomeSyncIndicator()]),
    )));
    expect(find.byIcon(Icons.sync), findsNothing);
    expect(find.byIcon(Icons.bluetooth), findsNothing);
  });

  testWidgets('shows a grey bluetooth 0 after the user pauses sync', (tester) async {
    final view = BleLaunchSyncView()
      ..setPaused(true)
      ..setProgress(const BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.done,
        deviceName: 'BM59',
        result: BleLaunchSyncResult(status: BleLaunchSyncStatus.cancelled),
      ));
    await tester.pumpWidget(await _indicator(view));

    final icon = tester.widget<Icon>(find.byIcon(Icons.bluetooth));
    expect(icon.color, ThemeData().colorScheme.onSurface);
    expect(find.text('0'), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
    expect(find.byIcon(Icons.sync), findsNothing);
    await tester.tap(find.byType(BleHomeSyncIndicator));
    await tester.pump();
    expect(view.detailsOpen, isTrue);
    expect(find.text('Meter sync paused'), findsOneWidget);
  });

  testWidgets('shows a grey bluetooth 0 after sync is cancelled', (tester) async {
    final view = BleLaunchSyncView()
      ..setProgress(const BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.done,
        result: BleLaunchSyncResult(status: BleLaunchSyncStatus.cancelled),
      ));
    await tester.pumpWidget(await _indicator(view));

    final icon = tester.widget<Icon>(find.byIcon(Icons.bluetooth));
    expect(icon.color, ThemeData().colorScheme.onSurface);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('hides when launch sync was skipped', (tester) async {
    final view = BleLaunchSyncView()
      ..setProgress(const BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.done,
        result: BleLaunchSyncResult(status: BleLaunchSyncStatus.skipped),
      ));
    await tester.pumpWidget(await _indicator(view));
    expect(find.byIcon(Icons.bluetooth), findsNothing);
  });

  testWidgets('shows a rotating refresh icon while scanning', (tester) async {
    final view = BleLaunchSyncView()
      ..setProgress(const BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.scanning,
        deviceName: 'BM59',
      ));
    await tester.pumpWidget(await _indicator(view));

    expect(find.byIcon(Icons.sync), findsOneWidget);
    expect(find.byIcon(Icons.bluetooth), findsNothing);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Looking for BM59…'), findsNothing);
  });

  testWidgets('shows a blue bluetooth icon while connecting', (tester) async {
    final view = BleLaunchSyncView()
      ..setProgress(const BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.connecting,
        deviceName: 'BM59',
      ));
    await tester.pumpWidget(await _indicator(view));

    final icon = tester.widget<Icon>(find.byIcon(Icons.bluetooth));
    expect(icon.color, Colors.blue);
    expect(find.byIcon(Icons.downloading), findsNothing);
    expect(find.byIcon(Icons.save_alt), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(view.detailsOpen, isFalse);

    await tester.tap(find.byType(BleHomeSyncIndicator));
    await tester.pump();
    expect(view.detailsOpen, isTrue);
  });

  testWidgets('keeps bluetooth icons aligned when the count is reserved', (tester) async {
    final view = BleLaunchSyncView()
      ..setProgress(const BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.connecting,
        deviceName: 'BM59',
      ));
    await tester.pumpWidget(await _indicator(view));
    final connectingX = tester.getTopLeft(find.byIcon(Icons.bluetooth)).dx;

    view.setProgress(const BleLaunchSyncProgress(
      phase: BleLaunchSyncPhase.done,
      result: BleLaunchSyncResult(status: BleLaunchSyncStatus.upToDate),
    ));
    await tester.pump();
    expect(tester.getTopLeft(find.byIcon(Icons.bluetooth)).dx, connectingX);
  });

  testWidgets('shows a bluetooth icon while reading', (tester) async {
    final view = BleLaunchSyncView()
      ..setProgress(const BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.reading,
        deviceName: 'BM59',
        deviceCount: 2,
      ));
    await tester.pumpWidget(await _indicator(view));

    expect(find.byIcon(Icons.bluetooth), findsOneWidget);
    expect(find.byIcon(Icons.downloading), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('keeps a green bluetooth icon after importing', (tester) async {
    final view = BleLaunchSyncView()
      ..setProgress(const BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.done,
        result: BleLaunchSyncResult(
          status: BleLaunchSyncStatus.imported,
          count: 3,
        ),
      ));
    await tester.pumpWidget(await _indicator(view));

    final icon = tester.widget<Icon>(find.byIcon(Icons.bluetooth));
    expect(icon.color, Colors.green);
    expect(view.detailsOpen, isFalse);

    await tester.tap(find.byType(BleHomeSyncIndicator));
    await tester.pump();
    expect(view.detailsOpen, isTrue);
    expect(find.byType(BleLaunchSyncCard), findsOneWidget);
  });

  testWidgets('keeps a grey-white bluetooth icon when nothing new was imported', (tester) async {
    final view = BleLaunchSyncView()
      ..setProgress(const BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.done,
        result: BleLaunchSyncResult(status: BleLaunchSyncStatus.upToDate),
      ));
    await tester.pumpWidget(await _indicator(view));

    final icon = tester.widget<Icon>(find.byIcon(Icons.bluetooth));
    expect(icon.color, Colors.white70);
  });

  testWidgets('shows 0 when no meter was found', (tester) async {
    final view = BleLaunchSyncView()
      ..setProgress(const BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.done,
        result: BleLaunchSyncResult(status: BleLaunchSyncStatus.notFound),
      ));
    await tester.pumpWidget(await _indicator(view));

    expect(find.byIcon(Icons.bluetooth), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.bluetooth));
    expect(icon.color, ThemeData().colorScheme.onSurface);
  });

  testWidgets('keeps a red bluetooth icon after a failure', (tester) async {
    final view = BleLaunchSyncView()
      ..setProgress(const BleLaunchSyncProgress(
        phase: BleLaunchSyncPhase.done,
        result: BleLaunchSyncResult(status: BleLaunchSyncStatus.failed),
      ));
    await tester.pumpWidget(await _indicator(view));

    final icon = tester.widget<Icon>(find.byIcon(Icons.bluetooth));
    expect(icon.color, ThemeData().colorScheme.error);
  });
}
