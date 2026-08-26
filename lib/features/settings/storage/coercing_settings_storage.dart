import 'package:flutter_settings_framework/flutter_settings_framework.dart';

/// SharedPreferences throws if a double key was stored as an [int].
///
/// Edadat JSON whole numbers decode as [int], and a naive copy writes them
/// with [SettingsStorage.setInt]. Reads for [DoubleSetting] then fail.
class CoercingSettingsStorage implements SettingsStorage {
  CoercingSettingsStorage(this._inner);

  final SettingsStorage _inner;

  @override
  Future<void> init() => _inner.init();

  @override
  String? getString(String key) => _inner.getString(key);

  @override
  Future<bool> setString(String key, String value) =>
      _inner.setString(key, value);

  @override
  int? getInt(String key) {
    try {
      final value = _inner.getInt(key);
      if (value != null) return value;
    } catch (_) {}
    try {
      return _inner.getDouble(key)?.toInt();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> setInt(String key, int value) => _inner.setInt(key, value);

  @override
  double? getDouble(String key) {
    try {
      final value = _inner.getDouble(key);
      if (value != null) return value;
    } catch (_) {}
    try {
      return _inner.getInt(key)?.toDouble();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> setDouble(String key, double value) =>
      _inner.setDouble(key, value);

  @override
  bool? getBool(String key) => _inner.getBool(key);

  @override
  Future<bool> setBool(String key, bool value) => _inner.setBool(key, value);

  @override
  List<String>? getStringList(String key) => _inner.getStringList(key);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      _inner.setStringList(key, value);

  @override
  bool containsKey(String key) => _inner.containsKey(key);

  @override
  Future<bool> remove(String key) => _inner.remove(key);

  @override
  Future<bool> clear() => _inner.clear();

  @override
  Set<String> getKeys() => _inner.getKeys();

  @override
  Future<void> reload() => _inner.reload();
}
