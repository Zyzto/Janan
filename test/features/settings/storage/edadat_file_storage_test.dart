import 'dart:convert';
import 'dart:io';

import 'package:blood_pressure_app/features/settings/registry.dart';
import 'package:blood_pressure_app/features/settings/storage/edadat_file_storage.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('edadat_import_');
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('imports general and health_connect then deletes them', () async {
    File(join(dir.path, 'general')).writeAsStringSync(jsonEncode({
      'weightInput': true,
      'lastVersion': 40,
      'themeMode': 1,
      'bleInput': 3,
    }));
    File(join(dir.path, 'health_connect')).writeAsStringSync(jsonEncode({
      'useHealthConnect': true,
      'syncOnAppStart': true,
    }));

    final storage = EdadatFileStorage(dir.path);
    final settings = await initializeSettings(
      registry: createAppSettingsRegistry(),
      storage: storage,
    );
    await storage.importLegacyFilesIfNeeded(settings.controller);

    expect(settings.controller.get(weightInputSetting), isTrue);
    expect(settings.controller.get(lastVersionSetting), 40);
    expect(settings.controller.get(themeModeSetting), 'dark');
    expect(
      settings.controller.get(bleInputSetting),
      'newBluetoothInputCrossPlatform',
    );
    expect(settings.controller.get(useHealthConnectSetting), isTrue);
    expect(settings.controller.get(syncOnAppStartSetting), isTrue);
    expect(File(join(dir.path, 'general')).existsSync(), isFalse);
    expect(File(join(dir.path, 'health_connect')).existsSync(), isFalse);
    expect(File(join(dir.path, EdadatFileStorage.fileName)).existsSync(), isTrue);
  });

  test('deletes leftover files without reimporting when Edadat exists', () async {
    File(join(dir.path, EdadatFileStorage.fileName)).writeAsStringSync(
      jsonEncode({'last_version': 58, 'weight_input': false}),
    );
    File(join(dir.path, 'general')).writeAsStringSync(jsonEncode({
      'weightInput': true,
      'lastVersion': 40,
    }));
    File(join(dir.path, 'health_connect')).writeAsStringSync(jsonEncode({
      'useHealthConnect': true,
    }));

    final storage = EdadatFileStorage(dir.path);
    final settings = await initializeSettings(
      registry: createAppSettingsRegistry(),
      storage: storage,
    );
    await storage.importLegacyFilesIfNeeded(settings.controller);

    expect(settings.controller.get(weightInputSetting), isFalse);
    expect(settings.controller.get(useHealthConnectSetting), isFalse);
    expect(File(join(dir.path, 'general')).existsSync(), isFalse);
    expect(File(join(dir.path, 'health_connect')).existsSync(), isFalse);
  });
}
