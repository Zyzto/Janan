import 'package:blood_pressure_app/model/storage/persistable_settings.dart';
import 'package:blood_pressure_app/model/storage/types/interval_storage_setting.dart';

/// Stores the interval objects that are needed in the app and provides named access to them.
class IntervalStoreManager extends PersistableSettings {
  IntervalStoreManager({
    IntervalStorage? mainPage,
    IntervalStorage? exportPage,
    IntervalStorage? statsPage,
  })  : _mainPage = mainPage ?? IntervalStorage(),
        _exportPage = exportPage ?? IntervalStorage(),
        _statsPage = statsPage ?? IntervalStorage() {
    _mainPage.addListener(notifyListeners);
    _exportPage.addListener(notifyListeners);
    _statsPage.addListener(notifyListeners);
  }

  /// Create a instance from a map created by [toMap].
  factory IntervalStoreManager.fromMap(Map<String, dynamic> map) {
    final n = IntervalStoreManager();
    n._applyMap(map);
    return n;
  }

  /// Create a instance from a [String] created by [toJson].
  factory IntervalStoreManager.fromJson(String json) {
    final map = decodeSettingsMap(json);
    if (map == null) return IntervalStoreManager();
    return IntervalStoreManager.fromMap(map);
  }

  IntervalStorage _mainPage;
  IntervalStorage _exportPage;
  IntervalStorage _statsPage;

  IntervalStorage get mainPage => _mainPage;
  set mainPage(IntervalStorage v) => _replace(_mainPage, v, (next) => _mainPage = next);

  IntervalStorage get exportPage => _exportPage;
  set exportPage(IntervalStorage v) => _replace(_exportPage, v, (next) => _exportPage = next);

  IntervalStorage get statsPage => _statsPage;
  set statsPage(IntervalStorage v) => _replace(_statsPage, v, (next) => _statsPage = next);

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
    'mainPage': _mainPage.toJson(),
    'exportPage': _exportPage.toJson(),
    'statsPage': _statsPage.toJson(),
  };

  void copyFrom(IntervalStoreManager other) {
    mainPage = IntervalStorage.fromJson(other._mainPage.toJson());
    exportPage = IntervalStorage.fromJson(other._exportPage.toJson());
    statsPage = IntervalStorage.fromJson(other._statsPage.toJson());
  }

  bool copyFromJson(String json) {
    final map = decodeSettingsMap(json);
    if (map == null) return false;
    copyFrom(IntervalStoreManager.fromMap(map));
    return true;
  }

  @override
  void reset() {
    mainPage = IntervalStorage();
    exportPage = IntervalStorage();
    statsPage = IntervalStorage();
  }

  @override
  void dispose() {
    _mainPage
      ..removeListener(notifyListeners)
      ..dispose();
    _exportPage
      ..removeListener(notifyListeners)
      ..dispose();
    _statsPage
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }

  void _applyMap(Map<String, dynamic> map) {
    final main = map['mainPage'];
    if (main is String) mainPage = IntervalStorage.fromJson(main);
    final export = map['exportPage'];
    if (export is String) exportPage = IntervalStorage.fromJson(export);
    final stats = map['statsPage'];
    if (stats is String) statsPage = IntervalStorage.fromJson(stats);
  }

  void _replace(
    IntervalStorage current,
    IntervalStorage next,
    void Function(IntervalStorage) assign,
  ) {
    if (identical(current, next)) return;
    current
      ..removeListener(notifyListeners)
      ..dispose();
    next.addListener(notifyListeners);
    assign(next);
    notifyListeners();
  }
}

extension IntervalStoreManagerUtil on IntervalStoreManager {
  IntervalStorage get(IntervalStoreManagerLocation type) => switch (type) {
    IntervalStoreManagerLocation.mainPage => mainPage,
    IntervalStoreManagerLocation.exportPage => exportPage,
    IntervalStoreManagerLocation.statsPage => statsPage,
  };
}

/// Locations supported by [IntervalStoreManager].
enum IntervalStoreManagerLocation {
  /// List on home screen.
  mainPage,
  /// All exported data.
  exportPage,
  /// Data for all statistics.
  statsPage,
}
