import 'package:blood_pressure_app/features/settings/app_settings.dart';
import 'package:blood_pressure_app/model/bluetooth_input_mode.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_settings_framework/flutter_settings_framework.dart';

/// Catalog tile that names the BLE and Ultra engines and describes each.
class BleEngineSettingsTile extends ConsumerWidget {
  const BleEngineSettingsTile({super.key});

  static const _options = [
    BluetoothInputMode.disabled,
    BluetoothInputMode.newBluetoothInputCrossPlatform,
    BluetoothInputMode.oldBluetoothInput,
  ];

  String? _description(BluetoothInputMode mode) => switch (mode) {
        BluetoothInputMode.disabled => null,
        BluetoothInputMode.newBluetoothInputCrossPlatform => 'bleEngineDesc'.tr(),
        BluetoothInputMode.oldBluetoothInput => 'ultraEngineDesc'.tr(),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appSettingsProvider).bleInput;
    final theme = Theme.of(context);
    return ListTile(
      leading: const Icon(Icons.bluetooth),
      title: Text('bluetoothInput'.tr()),
      subtitle: Text(mode.localize()),
      trailing: settingsChevronEnd(context),
      onTap: () async {
        final result = await SettingsDialog.select<BluetoothInputMode>(
          context: context,
          title: 'bluetoothInput'.tr(),
          options: _options,
          selectedValue: mode,
          itemBuilder: (option) {
            final desc = _description(option);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(option.localize()),
                if (desc != null)
                  Text(
                    desc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            );
          },
        );
        if (result != null) {
          await ref.setBleInput(result);
        }
      },
    );
  }
}
