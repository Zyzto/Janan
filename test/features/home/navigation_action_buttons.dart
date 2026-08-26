import 'package:blood_pressure_app/features/home/navigation_action_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../util.dart';

void main() {
  testWidgets('shows pill and add on blood pressure', (tester) async {
    await tester.pumpWidget(await materialApp(const NavigationActionButtons()));

    expect(find.byType(FloatingActionButton), findsNWidgets(2));
    expect(find.byIcon(Symbols.pill), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.file_download_outlined), findsNothing);
    expect(find.byIcon(Icons.settings), findsNothing);
    expect(find.byIcon(Icons.insights), findsNothing);
  });

  testWidgets('hides pill on weight', (tester) async {
    await tester.pumpWidget(await materialApp(
      const NavigationActionButtons(kind: NavigationActionKind.weight),
    ));

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Symbols.pill), findsNothing);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.file_download_outlined), findsNothing);
  });

  testWidgets('shows only export on statistics', (tester) async {
    await tester.pumpWidget(await materialApp(
      const NavigationActionButtons(kind: NavigationActionKind.export),
    ));

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
    expect(find.byIcon(Symbols.pill), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
  });
}
