import 'package:blood_pressure_app/features/export_import/model/export_preset.dart';
import 'package:blood_pressure_app/model/storage/export_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Deserializes serialized export preset', () {
    final settings = ExportSettings(
      presets: [
        ExportPreset('label1', ['a', 'B', 'c'], true),
        ExportPreset('label 2', ['huiasdolö822'], false),
      ],
    );

    final fromJson = ExportSettings.fromJson(settings.toJson());
    expect(fromJson.presets.length, settings.presets.length);
    expect(fromJson.presets[0].editable, settings.presets[0].editable);
    expect(fromJson.presets[0].id, settings.presets[0].id);
    expect(fromJson.presets[0].columns[1], settings.presets[0].columns[1]);
    expect(fromJson.presets[1].editable, settings.presets[1].editable);
    expect(fromJson.presets[1].columns[0], settings.presets[1].columns[0]);
  });
}
