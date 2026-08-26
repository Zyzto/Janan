import 'package:blood_pressure_app/features/export_import/ui/export_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  testWidgets('Shows share icon and text when sharing', (tester) async {
    await pumpApp(tester, await materialApp(ExportButton(share: true)));

    expect(find.byIcon(Icons.file_download_outlined), findsNothing);
    expect(find.byIcon(Icons.share), findsOneWidget);
    expect(find.text('EXPORT'), findsNothing);
    expect(find.text('SHARE'), findsOneWidget);
  });
  testWidgets('Shows download icon and export text when not sharing', (tester) async {
    await pumpApp(tester, await materialApp(ExportButton(share: false)));

    expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
    expect(find.byIcon(Icons.share), findsNothing);
    expect(find.text('EXPORT'), findsOneWidget);
    expect(find.text('SHARE'), findsNothing);
  });
}
