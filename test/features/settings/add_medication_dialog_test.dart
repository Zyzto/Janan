import 'package:blood_pressure_app/features/settings/add_medication_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blood_pressure_app/domain/domain.dart';

import '../../util.dart';

void main() {
  testWidgets('should prefill initialValue', (tester) async {
    await pumpApp(tester, await materialApp(AddMedicationDialog(
      initialValue: Medicine(
        designation: 'testmed 1',
        color: Colors.red.toARGB32(),
        dosis: Weight.mg(12.34),
      ),)));
    expect(find.text('testmed 1'), findsOneWidget);
    expect(find.text('12.34'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(MedicationUnit.values.length));
  });

  testWidgets('requires a name before save', (tester) async {
    await pumpApp(tester, await materialApp(const AddMedicationDialog()));
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a name'), findsOneWidget);
    expect(find.byType(AddMedicationDialog), findsOneWidget);
  });
}
