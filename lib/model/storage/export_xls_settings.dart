import 'package:blood_pressure_app/features/export_import/model/export_preset.dart';
import 'package:blood_pressure_app/model/storage/persistable_settings.dart';

class ExcelExportSettings extends PersistableSettings {
  ExcelExportSettings({
    String? activePreset,
  }) : _activePreset = activePreset ?? ExportPreset.appDefault.id;

  /// Create a instance from a map created by [toMap].
  factory ExcelExportSettings.fromMap(Map<String, dynamic> map) {
    final n = ExcelExportSettings();
    n._applyMap(map);
    return n;
  }

  /// Create a instance from a [String] created by [toJson].
  factory ExcelExportSettings.fromJson(String json) {
    final map = decodeSettingsMap(json);
    if (map == null) return ExcelExportSettings();
    return ExcelExportSettings.fromMap(map);
  }

  String _activePreset;

  String get activePreset => _activePreset;
  set activePreset(String v) {
    _activePreset = v;
    notifyListeners();
  }

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
    'activePreset': _activePreset,
  };

  void copyFrom(ExcelExportSettings other) {
    _activePreset = other._activePreset;
    notifyListeners();
  }

  bool copyFromJson(String json) {
    final map = decodeSettingsMap(json);
    if (map == null) return false;
    copyFrom(ExcelExportSettings.fromMap(map));
    return true;
  }

  @override
  void reset() => copyFrom(ExcelExportSettings());

  void _applyMap(Map<String, dynamic> map) {
    final preset = map['activePreset'];
    if (preset is String) _activePreset = preset;
  }
}
