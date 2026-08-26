import 'package:blood_pressure_app/features/export_import/model/column.dart';
import 'package:blood_pressure_app/features/export_import/model/export_preset.dart';
import 'package:blood_pressure_app/features/export_import/ui/columns_config/active_column_customizer.dart';
import 'package:blood_pressure_app/features/export_import/ui/columns_config/preset_editor.dart';
import 'package:blood_pressure_app/model/storage/export_csv_settings.dart';
import 'package:blood_pressure_app/model/storage/export_settings.dart';
import 'package:blood_pressure_app/model/storage/types/export_format_setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../util.dart';

void main() {
  testWidgets('switches active preset when saving a custom preset', (tester) async {
    final csvSettings = CsvExportSettings(
      activePreset: CustomPreset([]).id,
    );
    final exportSettings = ExportSettings(
      exportFormat: ExportFormat.csv,
      customPresetColumns: [
        NativeColumn.systolic.internalIdentifier,
        NativeColumn.diastolic.internalIdentifier,
      ]
    );
    await tester.pumpWidget(await materialApp(ActiveColumnCustomizer(),
      csvExportSettings: csvSettings,
      exportSettings: exportSettings,
    ));
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('Systolic'), findsOneWidget);
    expect(find.text('Diastolic'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'test preset');
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Custom'), findsNothing);
    expect(csvSettings.activePreset, 'test preset');
    expect(exportSettings.customPresetColumns, isEmpty);
  });
  
  testWidgets('automatically saves custom presets', (tester) async {
    final csvSettings = CsvExportSettings(
      activePreset: CustomPreset([]).id,
    );
    final exportSettings = ExportSettings(
        exportFormat: ExportFormat.csv,
        customPresetColumns: [
          NativeColumn.systolic.internalIdentifier,
          NativeColumn.diastolic.internalIdentifier,
        ]
    );
    await tester.pumpWidget(await materialApp(ActiveColumnCustomizer(),
      csvExportSettings: csvSettings,
      exportSettings: exportSettings,
    ));

    expect(exportSettings.customPresetColumns, hasLength(2));

    await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
    await tester.pumpAndSettle();

    expect(exportSettings.customPresetColumns, hasLength(1));
  });
  
  testWidgets("doesn't automatically save saved presets", (tester) async {
    final customPreset = ExportPreset(
        'test preset',
        [
          NativeColumn.systolic.internalIdentifier,
          NativeColumn.diastolic.internalIdentifier,
        ],
      true
    );
    final csvSettings = CsvExportSettings(
      activePreset: customPreset.id,
    );
    final exportSettings = ExportSettings(
      exportFormat: ExportFormat.csv,
      presets: [customPreset],
    );
    await tester.pumpWidget(await materialApp(ActiveColumnCustomizer(),
      csvExportSettings: csvSettings,
      exportSettings: exportSettings,
    ));
    expect(find.byType(PresetEditor), findsOneWidget);

    expect(exportSettings.presets.first.columns, hasLength(2));

    await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
    await tester.pumpAndSettle();

    expect(exportSettings.presets.first.columns, hasLength(2));

    expect(find.byIcon(Icons.save), findsOneWidget);
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    expect(exportSettings.presets, hasLength(1));
    expect(exportSettings.presets.first.columns, hasLength(1));
  });
  
  testWidgets("doesn't allow editing build-in presets", (tester) async {
    final customPreset = ExportPreset(
        'test preset',
        [
          NativeColumn.systolic.internalIdentifier,
          NativeColumn.diastolic.internalIdentifier,
        ],
        false
    );
    final csvSettings = CsvExportSettings(
      activePreset: customPreset.id,
    );
    final exportSettings = ExportSettings(
      exportFormat: ExportFormat.csv,
      presets: [customPreset],
    );
    await tester.pumpWidget(await materialApp(ActiveColumnCustomizer(),
      csvExportSettings: csvSettings,
      exportSettings: exportSettings,
    ));
    expect(find.byType(PresetEditor), findsNothing);
    expect(find.byIcon(Icons.delete_forever_outlined), findsNothing);
  });
  
  testWidgets('deletes the correct preset', (tester) async {
    final exportSettings = ExportSettings(
      exportFormat: ExportFormat.csv,
      presets: [
        ExportPreset('preset1', [], true),
        ExportPreset('preset2', [], true),
      ],
    );
    await tester.pumpWidget(await materialApp(ActiveColumnCustomizer(),
      exportSettings: exportSettings,
    ));
    expect(find.text('preset1'), findsNothing);
    expect(find.text('preset2'), findsNothing);
    expect(find.byType(DropdownButton<String>), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('preset1'), findsOneWidget);
    expect(find.text('preset2'), findsOneWidget);

    await tester.tap(find.text('preset2'));
    await tester.pumpAndSettle();

    expect(find.text('Custom'), findsNothing);
    expect(find.text('preset1'), findsNothing);
    expect(find.text('preset2'), findsOneWidget);
    expect(find.byIcon(Icons.delete_forever_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_forever_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('preset2'), findsNothing);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('preset1'), findsOneWidget);
    expect(find.text('preset2'), findsNothing);
  });

  testWidgets('ensures preset name uniqueness', (tester) async {
    final exportSettings = ExportSettings(
      exportFormat: ExportFormat.csv,
      presets: [
        ExportPreset('preset1', [], true),
        ExportPreset('preset2', [], true),
      ],
    );
    await tester.pumpWidget(await materialApp(ActiveColumnCustomizer(),
      exportSettings: exportSettings,
    ));
    expect(find.byType(DropdownButton<String>), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Custom'), findsOneWidget);

    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.save), findsOneWidget);


    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'uncreative');
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('This title already exists'), findsNothing);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'uncreative');
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('This title already exists'), findsOneWidget);
  });

}
