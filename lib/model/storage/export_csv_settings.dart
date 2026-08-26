import 'package:blood_pressure_app/features/export_import/model/export_preset.dart';
import 'package:blood_pressure_app/model/storage/convert_util.dart';
import 'package:blood_pressure_app/model/storage/persistable_settings.dart';

class CsvExportSettings extends PersistableSettings {
  CsvExportSettings({
    String? fieldDelimiter,
    String? textDelimiter,
    bool? exportHeadline,
    String? activePreset,
  })  : _fieldDelimiter = fieldDelimiter ?? ';',
        _textDelimiter = textDelimiter ?? '"',
        _exportHeadline = exportHeadline ?? true,
        _activePreset = activePreset ?? ExportPreset.appDefault.id;

  /// Create a instance from a map created by [toMap].
  factory CsvExportSettings.fromMap(Map<String, dynamic> map) {
    final n = CsvExportSettings();
    n._applyMap(map);
    return n;
  }

  /// Create a instance from a [String] created by [toJson].
  factory CsvExportSettings.fromJson(String json) {
    final map = decodeSettingsMap(json);
    if (map == null) return CsvExportSettings();
    return CsvExportSettings.fromMap(map);
  }

  String _fieldDelimiter;
  String _textDelimiter;
  bool _exportHeadline;
  String _activePreset;

  String get fieldDelimiter => _fieldDelimiter;
  set fieldDelimiter(String v) {
    _fieldDelimiter = v;
    notifyListeners();
  }

  String get textDelimiter => _textDelimiter;
  set textDelimiter(String v) {
    _textDelimiter = v;
    notifyListeners();
  }

  bool get exportHeadline => _exportHeadline;
  set exportHeadline(bool v) {
    _exportHeadline = v;
    notifyListeners();
  }

  String get activePreset => _activePreset;
  set activePreset(String v) {
    _activePreset = v;
    notifyListeners();
  }

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
    'fieldDelimiter': _fieldDelimiter,
    'textDelimiter': _textDelimiter,
    'exportHeadline': _exportHeadline,
    'activePreset': _activePreset,
  };

  void copyFrom(CsvExportSettings other) {
    _fieldDelimiter = other._fieldDelimiter;
    _textDelimiter = other._textDelimiter;
    _exportHeadline = other._exportHeadline;
    _activePreset = other._activePreset;
    notifyListeners();
  }

  bool copyFromJson(String json) {
    final map = decodeSettingsMap(json);
    if (map == null) return false;
    copyFrom(CsvExportSettings.fromMap(map));
    return true;
  }

  @override
  void reset() => copyFrom(CsvExportSettings());

  void _applyMap(Map<String, dynamic> map) {
    final field = map['fieldDelimiter'];
    if (field is String) _fieldDelimiter = field;
    final text = map['textDelimiter'];
    if (text is String) _textDelimiter = text;
    final headline = ConvertUtil.parseBool(map['exportHeadline']);
    if (headline != null) _exportHeadline = headline;
    final preset = map['activePreset'];
    if (preset is String) _activePreset = preset;
  }
}
