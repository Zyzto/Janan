import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:blood_pressure_app/core/repository/repo_context.dart';
import 'package:blood_pressure_app/app.dart';
import 'package:blood_pressure_app/features/settings/app_settings.dart';
import 'package:blood_pressure_app/features/settings/bluetooth_devices_screen.dart';
import 'package:blood_pressure_app/features/settings/body_profile_screen.dart';
import 'package:blood_pressure_app/features/settings/delete_data_screen.dart';
import 'package:blood_pressure_app/features/settings/edadat_prefs.dart';
import 'package:blood_pressure_app/features/settings/enter_timeformat_dialog.dart';
import 'package:blood_pressure_app/features/settings/graph_markings_screen.dart';
import 'package:blood_pressure_app/features/settings/registry.dart';
import 'package:blood_pressure_app/features/settings/storage/edadat_file_storage.dart';
import 'package:blood_pressure_app/features/settings/tiles/ble_engine_settings_tile.dart';
import 'package:blood_pressure_app/features/settings/version_screen.dart';
import 'package:blood_pressure_app/l10n/app_locales.dart';
import 'package:blood_pressure_app/logging.dart';
import 'package:blood_pressure_app/model/bluetooth_input_mode.dart';
import 'package:blood_pressure_app/model/storage/storage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';

/// Drop [visible]: false rows. The catalog page still builds every setting in a
/// section; Health Connect internals and other power-user flags must stay off
/// this list.
@visibleForTesting
List<Widget> visibleCatalogChildren(
  SettingsRegistry registry,
  List<Widget> children,
) {
  final visible = {
    for (final setting in registry.settings) setting.key: setting.visible,
  };
  return [
    for (final child in children)
      if (child is! SettingAnchor || (visible[child.settingKey] ?? true))
        child,
  ];
}

/// Searchable settings catalog backed by Edadat.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String>(
      ref.settings.provider(languageSetting),
      (previous, next) {
        final locale = localeFromLanguageKey(next);
        if (locale == null) {
          context.resetLocale();
        } else {
          context.setLocale(locale);
        }
      },
    );

    final registry = createAppSettingsRegistry();
    return RegistrySettingsPage(
      registry: registry,
      settings: ref.settings,
      title: 'settings'.tr(),
      searchHint: 'searchSettings'.tr(),
      sectionTitleBuilder: (key) => key.tr(),
      enumLabelBuilder: (key) {
        if (key == 'system') return 'system'.tr();
        if (languageSettingOptions.contains(key) && key != 'system') {
          final locale = localeFromLanguageKey(key);
          return locale == null ? key : getDisplayLanguage(locale);
        }
        return key.tr();
      },
      sectionContentBuilder: (sectionKey, defaultChildren) =>
          visibleCatalogChildren(registry, defaultChildren),
      tileBuilder: (setting, defaultTile) {
        if (setting.key == bleInputSetting.key) {
          return const BleEngineSettingsTile();
        }
        if (setting.key == dateFormatStringSetting.key) {
          final settings = ref.watch(appSettingsProvider);
          return ListTile(
            leading: const Icon(Icons.schedule),
            title: Text('enterTimeFormatScreen'.tr()),
            subtitle: Text(settings.dateFormatString),
            onTap: () async {
              final result = await showTimeFormatPickerDialog(
                context,
                settings.dateFormatString,
                settings.bottomAppBars,
              );
              if (result != null) {
                await ref.updateSetting(dateFormatStringSetting, result);
              }
            },
          );
        }
        if (setting is! ActionSetting) return defaultTile;
        if (setting.key == bodyProfileAction.key) {
          final settings = ref.watch(appSettingsProvider);
          return ActionSettingsTile(
            leading: const Icon(Icons.accessibility_new),
            title: Text('bodyProfile'.tr()),
            subtitle: Text(
              settings.hasBodyProfile
                  ? '${settings.bodyHeightCm!.round()} cm · ${settings.birthYear}'
                  : 'bodyProfileIncomplete'.tr(),
            ),
            onTap: () => _handleAction(context, ref, setting.key),
          );
        }
        if (setting.key == bluetoothDevicesAction.key) {
          final settings = ref.watch(appSettingsProvider);
          final enabled = settings.bleInput != BluetoothInputMode.disabled;
          return ActionSettingsTile(
            leading: const Icon(Icons.bluetooth_searching),
            title: Text('bluetoothDevices'.tr()),
            subtitle: settings.knownBleDev.isEmpty
                ? null
                : Text(settings.knownBleDev.map((device) => device.displayName).join(', ')),
            enabled: enabled,
            onTap: enabled ? () => _handleAction(context, ref, setting.key) : null,
          );
        }
        return ActionSettingsTile(
          leading: setting.icon != null ? Icon(setting.icon) : null,
          title: Text(setting.titleKey.tr()),
          subtitle: setting.subtitleKey != null ? Text(setting.subtitleKey!.tr()) : null,
          onTap: () => _handleAction(context, ref, setting.key),
        );
      },
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String key,
  ) async {
    switch (key) {
      case 'graph_settings':
        await Navigator.pushNamed(context, AppRoute.settingsGraph.path);
      case 'graph_markings':
        await Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => const GraphMarkingsScreen(),
        ));
      case 'body_profile':
        await Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => const BodyProfileScreen(),
        ));
      case 'medications':
        await Navigator.pushNamed(context, AppRoute.settingsMedications.path);
      case 'bluetooth_devices':
        await Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => const BluetoothDevicesScreen(),
        ));
      case 'health_connect_screen':
        await Navigator.pushNamed(context, AppRoute.settingsHealthConnect.path);
      case 'export_import':
        await Navigator.pushNamed(context, AppRoute.settingsExport.path);
      case 'delete_data':
        await Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => const DeleteDataScreen(),
        ));
      case 'replay_onboarding':
        await Navigator.pushNamed(context, AppRoute.onboarding.path);
      case 'version':
        await Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => const VersionScreen(),
        ));
      case 'source_code':
        final url = Uri.parse('https://github.com/Zyzto/blood-pressure-monitor-fl');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      case 'licenses':
        if (context.mounted) showLicensePage(context: context);
      case 'export_settings':
        await _exportSettings(context);
      case 'import_settings':
        await _importSettings(context);
      case 'logs_viewer':
        await Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => LogViewer(
            labels: LogViewerLabels(
              title: 'logs'.tr(),
              filterHint: 'searchSettings'.tr(),
            ),
          ),
        ));
    }
  }

  Future<void> _exportSettings(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final loader = context.fileSettingsLoader ?? await FileSettingsLoader.load();
    final controller = ProviderScope.containerOf(context, listen: false)
        .read(settingsControllerProvider);
    final archive = await loader.createArchive(
      edadatJson: jsonEncode(dumpEdadatController(controller)),
    );
    if (archive == null) {
      messenger.showSnackBar(SnackBar(content: Text('errCantCreateArchive'.tr())));
      return;
    }
    final compressed = ZipEncoder().encodeBytes(archive);
    await FilePicker.saveFile(
      type: FileType.any,
      fileName: 'bloodPressureSettings.zip',
      bytes: compressed,
    );
  }

  Future<void> _importSettings(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final exportSettings = context.exportSettings;
    final csvExportSettings = context.csvExportSettings;
    final pdfExportSettings = context.pdfExportSettings;
    final xlsExportSettings = context.excelExportSettings;
    final intervalStoreManager = context.intervalStoreManager;
    final exportColumnsManager = context.exportColumnsManager;
    final file = await FilePicker.pickFile();
    if (file == null) {
      messenger.showSnackBar(SnackBar(content: Text('errNoFileOpened'.tr())));
      return;
    }
    final path = file.path;
    if (path == null) {
      messenger.showSnackBar(SnackBar(content: Text('errCantReadFile'.tr())));
      return;
    }
    if (path.endsWith('db')) {
      messenger.showSnackBar(SnackBar(
        content: Text('error'.tr(namedArgs: {'msg': 'Format too old'})),
      ));
      return;
    }
    if (!path.endsWith('zip')) {
      messenger.showSnackBar(SnackBar(content: Text('errNotImportable'.tr())));
      return;
    }
    try {
      final decoded = ZipDecoder().decodeStream(InputFileStream(path));
      final dir = join(Directory.systemTemp.path, 'settingsBackup');
      await extractArchiveToDisk(decoded, dir);
      final loader = await FileSettingsLoader.load(path: dir);
      exportSettings.copyFrom(await loader.loadExportSettings());
      csvExportSettings.copyFrom(await loader.loadCsvExportSettings());
      pdfExportSettings.copyFrom(await loader.loadPdfExportSettings());
      xlsExportSettings.copyFrom(await loader.loadXlsExportSettings());
      intervalStoreManager.copyFrom(await loader.loadIntervalStorageManager());
      exportColumnsManager.copyFrom(await loader.loadExportColumnsManager());
      final edadatFile = File(join(dir, EdadatFileStorage.fileName));
      if (edadatFile.existsSync()) {
        final raw = jsonDecode(edadatFile.readAsStringSync());
        if (raw is Map<String, dynamic>) {
          if (!context.mounted) return;
          final controller = ProviderScope.containerOf(context, listen: false)
              .read(settingsControllerProvider);
          await importEdadatMap(controller, raw);
        }
      }
      messenger.showSnackBar(SnackBar(
        content: Text('success'.tr(namedArgs: {'msg': 'importSettings'.tr()})),
      ));
    } on FormatException catch (e, stack) {
      messenger.showSnackBar(SnackBar(content: Text('invalidZip'.tr())));
      Log.warning('invalid zip', error: e, stackTrace: stack);
    }
  }
}
