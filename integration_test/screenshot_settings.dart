import 'package:blood_pressure_app/app.dart';
import 'package:blood_pressure_app/features/shell/app_shell.dart';
import 'package:blood_pressure_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

void main() {
  testWidgets('Screenshot settings', (WidgetTester tester) async {
    await tester.pumpWidget(App());
    await tester.pumpAndSettle();
    await tester.pumpUntil(() => find.byType(AppHome).hasFound);
    // home

    await tester.tap(find.byKey(AppShell.navSettingsKey));
    await tester.pumpAndSettle();
    // settings

    await tester.dragFrom(
      tester.getCenter(find.text('Theme')),
      tester.getCenter(find.text('Theme')) - tester.getCenter(find.text('Time format')),
    );

    await tester.takeScreenshot('03-example_settings');

    await tester.scrollUntilVisible(find.text('Export / Import', skipOffstage: false), 50.0);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export / Import'));
    await tester.pumpAndSettle();

    await tester.takeScreenshot('05-export_example');
  });
}
