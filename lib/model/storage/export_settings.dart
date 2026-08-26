import 'dart:collection';

import 'package:blood_pressure_app/features/export_import/model/export_preset.dart';
import 'package:blood_pressure_app/model/storage/convert_util.dart';
import 'package:blood_pressure_app/model/storage/persistable_settings.dart';
import 'package:blood_pressure_app/model/storage/types/export_format_setting.dart';

/// General settings for exporting measurements that are applicable to all export formats.
class ExportSettings extends PersistableSettings {
  ExportSettings({
    ExportFormat? exportFormat,
    String? defaultExportDir,
    bool? exportAfterEveryEntry,
    bool? addTimestamp,
    List<ExportPreset>? presets,
    List<String>? customPresetColumns,
  })  : _exportFormat = exportFormat ?? ExportFormat.csv,
        _defaultExportDir = defaultExportDir ?? '',
        _exportAfterEveryEntry = exportAfterEveryEntry ?? false,
        _addTimestamp = addTimestamp ?? true,
        _presets = List<ExportPreset>.from(presets ?? const []),
        _customPresetColumns = List<String>.from(customPresetColumns ?? const []);

  /// Create a instance from a map created by [toMap].
  factory ExportSettings.fromMap(Map<String, dynamic> map) {
    final n = ExportSettings();
    n._applyMap(map);
    return n;
  }

  /// Create a instance from a [String] created by [toJson].
  factory ExportSettings.fromJson(String json) {
    final map = decodeSettingsMap(json);
    if (map == null) return ExportSettings();
    return ExportSettings.fromMap(map);
  }

  ExportFormat _exportFormat;
  String _defaultExportDir;
  bool _exportAfterEveryEntry;
  bool _addTimestamp;
  List<ExportPreset> _presets;
  List<String> _customPresetColumns;

  ExportFormat get exportFormat => _exportFormat;
  set exportFormat(ExportFormat v) {
    _exportFormat = v;
    notifyListeners();
  }

  String get defaultExportDir => _defaultExportDir;
  set defaultExportDir(String v) {
    _defaultExportDir = v;
    notifyListeners();
  }

  bool get exportAfterEveryEntry => _exportAfterEveryEntry;
  set exportAfterEveryEntry(bool v) {
    _exportAfterEveryEntry = v;
    notifyListeners();
  }

  bool get addTimestamp => _addTimestamp;
  set addTimestamp(bool v) {
    _addTimestamp = v;
    notifyListeners();
  }

  /// Presets defined by the user.
  ///
  /// The list is a copy. Assign back through the setter to persist edits.
  List<ExportPreset> get presets => List<ExportPreset>.from(_presets);
  set presets(List<ExportPreset> v) {
    _presets = List<ExportPreset>.from(v);
    notifyListeners();
  }

  List<String> get customPresetColumns => UnmodifiableListView(_customPresetColumns);
  set customPresetColumns(List<String> v) {
    _customPresetColumns = List<String>.from(v);
    notifyListeners();
  }

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
    'exportFormat': _exportFormat.serialize(),
    'defaultExportDir': _defaultExportDir,
    'exportAfterEveryEntry': _exportAfterEveryEntry,
    'addTimestamp': _addTimestamp,
    'presets': _encodePresets(_presets),
    'customPresetColumns': _customPresetColumns,
  };

  void copyFrom(ExportSettings other) {
    _exportFormat = other._exportFormat;
    _defaultExportDir = other._defaultExportDir;
    _exportAfterEveryEntry = other._exportAfterEveryEntry;
    _addTimestamp = other._addTimestamp;
    _presets = List<ExportPreset>.from(other._presets);
    _customPresetColumns = List<String>.from(other._customPresetColumns);
    notifyListeners();
  }

  bool copyFromJson(String json) {
    final map = decodeSettingsMap(json);
    if (map == null) return false;
    copyFrom(ExportSettings.fromMap(map));
    return true;
  }

  @override
  void reset() => copyFrom(ExportSettings());

  void _applyMap(Map<String, dynamic> map) {
    if (map.containsKey('exportFormat')) {
      _exportFormat = ExportFormat.deserialize(map['exportFormat']);
    }
    final dir = map['defaultExportDir'];
    if (dir is String) _defaultExportDir = dir;
    final afterEvery = ConvertUtil.parseBool(map['exportAfterEveryEntry']);
    if (afterEvery != null) _exportAfterEveryEntry = afterEvery;
    final timestamp = ConvertUtil.parseBool(map['addTimestamp']);
    if (timestamp != null) _addTimestamp = timestamp;
    if (map.containsKey('presets')) {
      _presets = _decodePresets(map['presets']);
    }
    final columns = ConvertUtil.parseList<String>(map['customPresetColumns']);
    if (columns != null) _customPresetColumns = List<String>.from(columns);
  }
}

List<Map<String, dynamic>> _encodePresets(List<ExportPreset> presets) => [
  for (final preset in presets)
    {
      'label': preset.id,
      'columns': preset.columns,
      'editable': preset.editable,
    },
];

List<ExportPreset> _decodePresets(Object? value) {
  if (value is! List) return [];
  final decoded = <ExportPreset>[];
  for (final presetData in value) {
    if (presetData is! Map) continue;
    if (!presetData.containsKey('label')) continue;
    final label = presetData['label'];
    if (label is! String) continue;
    final editable = presetData['editable'];
    if (editable is! bool) continue;
    if (!presetData.containsKey('columns')) continue;
    final columns = ConvertUtil.parseList<String>(presetData['columns']);
    if (columns is! List<String>) continue;
    decoded.add(ExportPreset(label, columns, editable));
  }
  return decoded;
}
