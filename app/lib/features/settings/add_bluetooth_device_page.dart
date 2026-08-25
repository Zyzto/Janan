// ignore_for_file: strict_raw_type

import 'package:blood_pressure_app/features/bluetooth/backend/bluetooth_backend.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/bluetooth_cubit.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/device_scan_cubit.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/closed_bluetooth_input.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/device_scan_placeholder.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/device_selection.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/model/storage/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Scan and remember a bluetooth device without taking a measurement.
class AddBluetoothDevicePage extends StatefulWidget {
  /// Create a page to add a remembered bluetooth device.
  const AddBluetoothDevicePage({
    super.key,
    required this.manager,
    this.bluetoothCubit,
    this.deviceScanCubit,
  });

  /// Bluetooth backend used for scanning.
  final BluetoothManager manager;

  /// Function to customize [BluetoothCubit] creation.
  @visibleForTesting
  final BluetoothCubit Function()? bluetoothCubit;

  /// Function to customize [DeviceScanCubit] creation.
  @visibleForTesting
  final DeviceScanCubit Function()? deviceScanCubit;

  @override
  State<AddBluetoothDevicePage> createState() => _AddBluetoothDevicePageState();
}

class _AddBluetoothDevicePageState extends State<AddBluetoothDevicePage> {
  late final BluetoothCubit _bluetoothCubit;
  DeviceScanCubit? _deviceScanCubit;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _bluetoothCubit = widget.bluetoothCubit?.call()
        ?? BluetoothCubit(manager: widget.manager);
    if (_bluetoothCubit.state is BluetoothStateReady) {
      _scanning = true;
    }
  }

  @override
  void dispose() {
    _deviceScanCubit?.close();
    _bluetoothCubit.close();
    super.dispose();
  }

  DeviceScanCubit _scanCubit(Settings settings) =>
      _deviceScanCubit ??= widget.deviceScanCubit?.call()
          ?? DeviceScanCubit(
            manager: widget.manager,
            settings: settings,
            autoRead: false,
          );

  Future<void> _accept(BuildContext context, BluetoothDevice device) async {
    await _scanCubit(context.read<Settings>()).acceptDevice(device);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final settings = context.watch<Settings>();
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.addBluetoothDevice),
      ),
      body: _scanning
          ? BlocBuilder<DeviceScanCubit, DeviceScanState>(
              bloc: _scanCubit(settings),
              builder: (context, state) => switch (state) {
                DeviceListLoading() => const DeviceScanPlaceholder(expand: true),
                DeviceListAvailable() => DeviceSelection(
                  expand: true,
                  scanResults: state.devices,
                  otherDevices: state.otherDevices,
                  onAccepted: (dev) => _accept(context, dev),
                ),
                SingleDeviceAvailable() => DeviceSelection(
                  expand: true,
                  scanResults: [state.device],
                  onAccepted: (dev) => _accept(context, dev),
                ),
                DeviceSelected() => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(localizations.btnCancel),
                      ),
                    ],
                  ),
                ),
              },
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ClosedBluetoothInput(
                bluetoothCubit: _bluetoothCubit,
                onStarted: () {
                  if (_bluetoothCubit.state is BluetoothStateReady) {
                    setState(() => _scanning = true);
                  }
                },
              ),
            ),
    );
  }
}
