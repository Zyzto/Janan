import 'package:blood_pressure_app/features/settings/body_profile_screen.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/model/body_sex.dart';
import 'package:blood_pressure_app/model/storage/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util.dart';

void main() {
  testWidgets('writes height, birth year, sex, and athlete mode', (tester) async {
    final settings = Settings();
    await tester.pumpWidget(materialApp(const BodyProfileScreen(), settings: settings));
    final localizations = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.enterText(find.byType(TextField).at(0), '180');
    await tester.enterText(find.byType(TextField).at(1), '1991');
    await tester.tap(find.byType(DropdownButton<BodySex?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(localizations.bodySexMale).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(settings.bodyHeightCm, 180);
    expect(settings.birthYear, 1991);
    expect(settings.bodySex, BodySex.male);
    expect(settings.athleteMode, isTrue);
  });
}
