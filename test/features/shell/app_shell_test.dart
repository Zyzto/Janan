import 'package:blood_pressure_app/core/settings/storage_providers.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/ble_launch_sync_host.dart';
import 'package:blood_pressure_app/features/data_picker/interval_picker.dart';
import 'package:blood_pressure_app/features/home/navigation_action_buttons.dart';
import 'package:blood_pressure_app/features/shell/app_shell.dart';
import 'package:blood_pressure_app/model/storage/interval_store_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safaeh/safaeh.dart';

import '../../util.dart';

void main() {
  testWidgets('keeps the nav bar while sliding to another tab', (tester) async {
    final presence = HomePresenceObserver();
    await tester.pumpWidget(
      await _minimalShell(
        presence: presence,
        pages: const [
          Text('home-page'),
          Text('weight-page'),
          Text('stats-page'),
          Text('settings-page'),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('home-page'), findsOneWidget);
    expect(find.text('settings-page'), findsNothing);
    expect(find.byType(SafaehFloatingNavBar), findsOneWidget);
    expect(presence.onHome, isTrue);

    await tester.tap(find.byKey(AppShell.navSettingsKey));
    await tester.pump();
    expect(find.byType(SafaehFloatingNavBar), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('settings-page'), findsOneWidget);
    expect(find.text('home-page'), findsNothing);
    expect(find.byType(SafaehFloatingNavBar), findsOneWidget);
    expect(presence.onHome, isFalse);

    await tester.tap(find.byKey(AppShell.navHomeKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('home-page'), findsOneWidget);
    expect(presence.onHome, isTrue);
  });

  testWidgets('swiping left and right changes the selected tab', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final presence = HomePresenceObserver();
    await tester.pumpWidget(
      await _minimalShell(
        presence: presence,
        pages: const [
          SizedBox.expand(child: Text('home-page')),
          SizedBox.expand(child: Text('weight-page')),
          SizedBox.expand(child: Text('stats-page')),
          SizedBox.expand(child: Text('settings-page')),
        ],
      ),
    );
    await tester.pump();

    final pages = find.byType(PageView);
    await tester.fling(pages, const Offset(-300, 0), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('weight-page'), findsOneWidget);
    expect(find.byType(SafaehFloatingNavBar), findsOneWidget);
    expect(presence.onHome, isFalse);

    await tester.fling(pages, const Offset(-300, 0), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('stats-page'), findsOneWidget);

    await tester.fling(pages, const Offset(-300, 0), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('settings-page'), findsOneWidget);

    await tester.fling(pages, const Offset(300, 0), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('stats-page'), findsOneWidget);
  });

  testWidgets('keeps the range filter still while title and content change', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      await _minimalShell(
        pages: const [
          Center(child: Text('home-page')),
          Center(child: Text('weight-page')),
          Center(child: Text('stats-page')),
          Center(child: Text('settings-page')),
        ],
      ),
    );
    await tester.pump();

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('title')),
      findsOneWidget,
    );
    expect(find.text('home-page'), findsOneWidget);
    expect(find.byType(IntervalPicker), findsOneWidget);
    expect(find.byType(NavigationActionButtons), findsOneWidget);
    final filterY = tester.getCenter(find.byType(IntervalPicker)).dy;
    final fabBottom = tester.getBottomLeft(find.byType(NavigationActionButtons)).dy;

    await tester.tap(find.byKey(AppShell.navWeightKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('weight')),
      findsOneWidget,
    );
    expect(find.text('weight-page'), findsOneWidget);
    expect(find.byType(IntervalPicker), findsOneWidget);
    expect(tester.getCenter(find.byType(IntervalPicker)).dy, filterY);
    expect(find.byType(NavigationActionButtons), findsOneWidget);
    expect(tester.getBottomLeft(find.byType(NavigationActionButtons)).dy, fabBottom);

    await tester.tap(find.byKey(AppShell.navStatisticsKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('statistics'),
      ),
      findsOneWidget,
    );
    expect(find.text('stats-page'), findsOneWidget);
    expect(tester.getCenter(find.byType(IntervalPicker)).dy, filterY);
    expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(tester.getBottomLeft(find.byType(NavigationActionButtons)).dy, fabBottom);

    await tester.tap(find.byKey(AppShell.navSettingsKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(IntervalPicker), findsNothing);
    expect(find.text('settings-page'), findsOneWidget);
  });

  testWidgets('hides the weight tab when weight features are off', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      await _minimalShell(
        showWeight: false,
        pages: const [
          SizedBox.expand(child: Text('home-page')),
          SizedBox.expand(child: Text('weight-page')),
          SizedBox.expand(child: Text('stats-page')),
          SizedBox.expand(child: Text('settings-page')),
        ],
      ),
    );
    await tester.pump();

    expect(find.byKey(AppShell.navWeightKey), findsNothing);
    expect(find.text('weight-page'), findsNothing);
    expect(find.text('home-page'), findsOneWidget);

    final pages = find.byType(PageView);
    await tester.fling(pages, const Offset(-300, 0), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('stats-page'), findsOneWidget);
    expect(find.text('weight-page'), findsNothing);
  });

  testWidgets('stays on settings when the weight tab is hidden', (tester) async {
    final showWeight = ValueNotifier(true);
    addTearDown(showWeight.dispose);

    await tester.pumpWidget(
      await _minimalShell(
        showWeightListenable: showWeight,
        pages: const [
          Text('home-page'),
          Text('weight-page'),
          Text('stats-page'),
          Text('settings-page'),
        ],
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(AppShell.navSettingsKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('settings-page'), findsOneWidget);
    expect(find.byKey(AppShell.navWeightKey), findsOneWidget);

    showWeight.value = false;
    await tester.pump();
    expect(find.text('settings-page'), findsOneWidget);
    expect(find.byKey(AppShell.navWeightKey), findsNothing);
    expect(find.text('weight-page'), findsNothing);
  });
}

Future<Widget> _minimalShell({
  HomePresenceObserver? presence,
  required List<Widget> pages,
  bool showWeight = true,
  ValueNotifier<bool>? showWeightListenable,
}) async {
  final settings = await createTestSettings();
  final shell = showWeightListenable == null
      ? AppShell(
          homePresence: presence,
          showWeight: showWeight,
          pages: pages,
        )
      : ValueListenableBuilder<bool>(
          valueListenable: showWeightListenable,
          builder: (_, enabled, _) => AppShell(
            homePresence: presence,
            showWeight: enabled,
            pages: pages,
          ),
        );
  return ProviderScope(
    overrides: [
      settingsControllerProvider.overrideWithValue(settings.controller),
      settingsSearchIndexProvider.overrideWithValue(settings.searchIndex),
      settingsProvidersProvider.overrideWithValue(settings),
      intervalStoreManagerProvider.overrideWithValue(IntervalStoreManager()),
    ],
    child: SafaehTheme(
      data: const SafaehThemeData(),
      child: MaterialApp(home: shell),
    ),
  );
}
