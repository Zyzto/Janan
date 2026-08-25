import 'package:app_settings/app_settings.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/bluetooth_cubit.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/logging.dart';
import 'package:blood_pressure_app/model/storage/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A closed ble input that shows the adapter state and allows to start the input.
class ClosedBluetoothInput extends StatelessWidget with TypeLogger {
  /// Show adapter state and allow starting inputs
  const ClosedBluetoothInput({super.key,
    required this.bluetoothCubit,
    required this.onStarted,
    this.inputInfo,
  });

  /// State update provider and interaction with the device.
  final BluetoothCubit bluetoothCubit;

  /// Called when the user taps on an active start button.
  final void Function() onStarted;

  /// Callback called when the user wants to know more about this input.
  ///
  /// The info icon is not shown when this is null.
  final void Function()? inputInfo;

  String _readyLabel(BuildContext context, AppLocalizations localizations) {
    final known = context.watch<Settings>().knownBleDev;
    if (known.isEmpty) return localizations.bluetoothInput;
    if (known.length == 1) {
      return localizations.readFromDevice(known.first.displayName);
    }
    return localizations.readFromDevices(known.length);
  }

  Widget _buildStatus({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color containerColor,
    required Color onContainerColor,
    required void Function() onTap,
    bool emphasize = false,
  }) {
    final theme = Theme.of(context);
    return Card(
      color: containerColor,
      margin: const EdgeInsets.only(top: 0, bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: emphasize
              ? theme.colorScheme.primary
              : onContainerColor.withValues(alpha: 0.12),
          foregroundColor: emphasize
              ? theme.colorScheme.onPrimary
              : onContainerColor,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (inputInfo != null)
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: inputInfo!,
              ),
            if (emphasize)
              FilledButton(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onTap,
                child: Text(AppLocalizations.of(context)!.connect),
              )
            else
              Icon(Icons.chevron_right, color: onContainerColor),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return BlocBuilder<BluetoothCubit, BluetoothState>(
      bloc: bluetoothCubit,
      builder: (context, BluetoothState state) {
        logger.finer('Called with state: $state');
        return switch(state) {
          BluetoothStateInitial() => const SizedBox.shrink(),
          BluetoothStateUnfeasible() => const SizedBox.shrink(),
          BluetoothStateUnauthorized() => _buildStatus(
            context: context,
            title: localizations.errBleNoPerms,
            subtitle: localizations.tapToGrantBlePermission,
            icon: Icons.bluetooth_disabled,
            containerColor: theme.colorScheme.errorContainer,
            onContainerColor: theme.colorScheme.onErrorContainer,
            onTap: () async {
              await AppSettings.openAppSettings();
              bluetoothCubit.forceRefresh();
            },
          ),
          BluetoothStateDisabled() => _buildStatus(
            context: context,
            title: localizations.bluetoothDisabled,
            subtitle: localizations.tapToEnableBluetooth,
            icon: Icons.bluetooth_disabled,
            containerColor: theme.colorScheme.tertiaryContainer,
            onContainerColor: theme.colorScheme.onTertiaryContainer,
            onTap: () async {
              final bluetoothOn = await bluetoothCubit.enableBluetooth();
              if (bluetoothOn == false) {
                await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
              }
              bluetoothCubit.forceRefresh();
            },
          ),
          BluetoothStateReady() => _buildStatus(
            context: context,
            title: _readyLabel(context, localizations),
            subtitle: localizations.tapToConnect,
            icon: Icons.bluetooth,
            containerColor: theme.colorScheme.primaryContainer,
            onContainerColor: theme.colorScheme.onPrimaryContainer,
            emphasize: true,
            onTap: onStarted,
          )
        };
      },
    );
  }
}
