import 'package:blood_pressure_app/features/settings/initialize_app_settings.dart';
import 'package:blood_pressure_app/features/settings/registry.dart';
import 'package:blood_pressure_app/features/settings/storage/coercing_settings_storage.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('reads SharedPreferences ints as doubles', () async {
    SharedPreferences.setMockInitialValues({
      graphLineThicknessSetting.key: 3,
      needlePinBarWidthSetting.key: 5,
      bodyHeightCmSetting.key: 180,
    });
    final prefs = SharedPreferencesStorage();
    await prefs.init();
    expect(
      () => prefs.getDouble(graphLineThicknessSetting.key),
      throwsA(isA<TypeError>()),
    );

    final storage = CoercingSettingsStorage(prefs);
    expect(storage.getDouble(graphLineThicknessSetting.key), 3.0);
    expect(storage.getDouble(needlePinBarWidthSetting.key), 5.0);
    expect(storage.getDouble(bodyHeightCmSetting.key), 180.0);
  });

  test('copySettingsStorage writes DoubleSetting keys as doubles', () async {
    final from = MemoryStorage();
    await from.setInt(graphLineThicknessSetting.key, 3);
    await from.setInt(lastVersionSetting.key, 58);
    final to = MemoryStorage();

    await copySettingsStorage(from, to);

    expect(to.getDouble(graphLineThicknessSetting.key), 3.0);
    expect(to.getInt(graphLineThicknessSetting.key), isNull);
    expect(to.getInt(lastVersionSetting.key), 58);
  });

  test('initializeSettings succeeds when prefs stored ints for doubles', () async {
    SharedPreferences.setMockInitialValues({
      graphLineThicknessSetting.key: 3,
      lastVersionSetting.key: 58,
    });
    final storage = CoercingSettingsStorage(SharedPreferencesStorage());
    await storage.init();
    final loaded = await initializeSettings(
      registry: createAppSettingsRegistry(),
      storage: storage,
    );
    expect(loaded.controller.get(graphLineThicknessSetting), 3.0);
    expect(loaded.controller.get(lastVersionSetting), 58);
  });
}
