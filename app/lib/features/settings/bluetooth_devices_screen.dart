// ignore_for_file: strict_raw_type

import 'package:blood_pressure_app/components/confirm_deletion_dialog.dart';
import 'package:blood_pressure_app/features/bluetooth/backend/bluetooth_manager.dart';
import 'package:blood_pressure_app/features/settings/add_bluetooth_device_page.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/model/known_ble_device.dart';
import 'package:blood_pressure_app/model/storage/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Screen to view, add, and forget remembered bluetooth devices.
class BluetoothDevicesScreen extends StatelessWidget {
  /// Create a screen to manage remembered bluetooth devices.
  const BluetoothDevicesScreen({
    super.key,
    this.manager,
    this.addDevicePageBuilder,
  });

  /// Optional manager used when adding a device.
  final BluetoothManager? manager;

  /// Optional builder used by tests to replace the add-device page.
  @visibleForTesting
  final WidgetBuilder? addDevicePageBuilder;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    final localizations = AppLocalizations.of(context)!;
    final devices = settings.knownBleDev;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.bluetoothDevices),
      ),
      body: ListView(
        children: [
          if (devices.isEmpty)
            ListTile(
              title: Text(localizations.noBluetoothDevices),
            ),
          for (final device in devices)
            _DeviceTile(
              device: device,
              onForget: () => _forget(context, settings, device),
              onAutoSyncChanged: (value) => _setAutoSync(settings, device, value),
            ),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(localizations.addBluetoothDevice),
            onTap: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: addDevicePageBuilder ?? (context) => AddBluetoothDevicePage(
                    manager: manager ?? BluetoothManager.create(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _forget(
    BuildContext context,
    Settings settings,
    KnownBleDevice device,
  ) async {
    if (!await showConfirmDeletionDialog(context)) return;
    settings.knownBleDev = settings.knownBleDev
        .where((known) => known.id != device.id)
        .toList();
  }

  void _setAutoSync(Settings settings, KnownBleDevice device, bool value) {
    settings.knownBleDev = [
      for (final known in settings.knownBleDev)
        if (known.id == device.id) known.copyWith(autoSync: value) else known,
    ];
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.onForget,
    required this.onAutoSyncChanged,
  });

  final KnownBleDevice device;
  final VoidCallback onForget;
  final ValueChanged<bool> onAutoSyncChanged;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_heart_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (device.displayName != device.id)
                        Text(
                          device.id,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: localizations.confirmDelete,
                  onPressed: onForget,
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(localizations.autoSyncDevice),
              subtitle: Text(localizations.autoSyncDeviceDesc),
              value: device.autoSync,
              onChanged: onAutoSyncChanged,
            ),
          ],
        ),
      ),
    );
  }
}
