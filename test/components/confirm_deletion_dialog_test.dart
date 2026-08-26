import 'package:blood_pressure_app/components/confirm_deletion_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safaeh/safaeh.dart';

import '../util.dart';

void main() {
  testWidgets('shows entire content', (tester) async {
    usePhoneTestSurface(tester);
    await loadDialog(tester, showConfirmDeletionDialog);
    await tester.pumpAndSettle();
    expect(find.byType(SafaehConfirmSheet), findsOneWidget);
    expect(find.byKey(const ValueKey('safaeh_cancel')), findsOneWidget);
    expect(find.byKey(const ValueKey('safaeh_confirm')), findsOneWidget);

    expect(find.text('Confirm deletion'), findsOneWidget);
    expect(find.text('Delete this entry? (You can turn off these confirmations in the settings.)'), findsOneWidget);
    expect(find.text('CANCEL'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });
}
