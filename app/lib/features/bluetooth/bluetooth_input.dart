// TODO: cleanup types
// ignore_for_file: strict_raw_type

import 'dart:async';

import 'package:blood_pressure_app/features/bluetooth/backend/bluetooth_backend.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/ble_measurement_duplicates.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/ble_read_cubit.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/bluetooth_cubit.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/characteristics/ble_measurement_data.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/device_scan_cubit.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/closed_bluetooth_input.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/device_connecting_placeholder.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/device_scan_placeholder.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/device_selection.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/input_card.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/measurement_failure.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/measurement_multiple.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/measurement_success.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/logging.dart';
import 'package:blood_pressure_app/model/bluetooth_measurement_import_mode.dart';
import 'package:blood_pressure_app/model/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_data_store/health_data_store.dart';
import 'package:provider/provider.dart';

/// Class for inputting measurement through bluetooth.
class BluetoothInput extends StatefulWidget {
  /// Create a measurement input through bluetooth.
  const BluetoothInput({
    super.key,
    required this.onMeasurement,
    required this.onAllMeasurements,
    required this.manager,
    this.bluetoothCubit,
    this.deviceScanCubit,
    this.bleReadCubit,
  });

  /// Bluetooth Backend manager
  final BluetoothManager manager;

  /// Called when a measurement was received through bluetooth.
  final void Function(BloodPressureRecord data) onMeasurement;

  /// Called when the user chooses to import all received measurements through bluetooth.
  final void Function(List<BloodPressureRecord> data) onAllMeasurements;

  /// Function to customize [BluetoothCubit] creation.
  final BluetoothCubit Function()? bluetoothCubit;

  /// Function to customize [DeviceScanCubit] creation.
  final DeviceScanCubit Function()? deviceScanCubit;

  /// Function to customize [BleReadCubit] creation.
  final BleReadCubit Function()? bleReadCubit;

  @override
  State<BluetoothInput> createState() => BluetoothInputState();
}

/// Read bluetooth input happy workflow:
/// - build is called and renders ClosedBluetoothInput with read bluetooth input button
/// - User clicks button, toggles _isActive
/// - _buildActive is called, waits for device_scan_state.DeviceSelected
/// - _buildReadDevice is called, waits for ble_read_state.BleReadSuccess
/// - onMeasurement callback triggered
@visibleForTesting
class BluetoothInputState extends State<BluetoothInput> with TypeLogger {
  /// Whether the user initiated reading bluetooth input
  @visibleForTesting
  bool isActive = false;
  /// Guard against auto-importing the same batch of measurements twice.
  @visibleForTesting
  bool hasImported = false;

  late final BluetoothCubit _bluetoothCubit;
  DeviceScanCubit? _deviceScanCubit;
  BleReadCubit? _deviceReadCubit;

  StreamSubscription<BluetoothState>? _bluetoothSubscription;

  /// Data received from reading bluetooth values.
  ///
  /// Its presence indicates that this input is done.
  BleMeasurementData? _finishedData;

  /// Shown when auto-import could not load the diary to filter duplicates.
  String? _importError;

  @override
  void initState() {
    super.initState();
    _bluetoothCubit = widget.bluetoothCubit?.call() ?? BluetoothCubit(manager: widget.manager);
    _maybeAutostart(context.read(), _bluetoothCubit.state);
  }

  @override
  void dispose() {
    unawaited(_bluetoothSubscription?.cancel());
    unawaited(_bluetoothCubit.close());
    unawaited(_deviceScanCubit?.close());
    unawaited(_deviceReadCubit?.close());
    super.dispose();
  }

  void _returnToIdle() async {
    hasImported = false;
    if (isActive) {
      setState(() {
        isActive = false;
        _finishedData = null;
        _importError = null;
      });
    }

    await _deviceReadCubit?.close();
    await _deviceScanCubit?.close();
    await _bluetoothSubscription?.cancel();
    _deviceReadCubit = null;
    _deviceScanCubit = null;
    _bluetoothSubscription = null;
  }

  /// Automatically start the input when bluetooth auto-import is enabled
  void _maybeAutostart(Settings settings, BluetoothState state) {
    if (!settings.autostartBluetoothInput ||
        isActive ||
        _finishedData != null ||
        state is! BluetoothStateReady) {
      return;
    }
    logger.finer('_maybeAutostart: starting bluetooth input');
    setState(() => isActive = true);
  }

  @override
  Widget build(BuildContext context) {
    const SizeChangedLayoutNotification().dispatch(context);
    logger.finer('build[_isActive: $isActive, _finishedData: $_finishedData]');

    if (_importError != null) {
      return MeasurementFailure(
        onTap: _returnToIdle,
        reason: _importError!,
      );
    }

    if (_finishedData != null) {
      return MeasurementSuccess(
        onTap: _returnToIdle,
        data: _finishedData!,
      );
    }

    if (isActive) {
      return _buildActive(context);
    }

    final settings = context.watch<Settings>();
    return BlocListener<BluetoothCubit, BluetoothState>(
      bloc: _bluetoothCubit,
      listener: (context, state) => _maybeAutostart(settings, state),
      child: ClosedBluetoothInput(
        bluetoothCubit: _bluetoothCubit,
        onStarted: () => setState(() => isActive = true),
        inputInfo: () async {
          logger.finer('build.inputInfo[mounted: ${context.mounted}]');
          if (context.mounted) {
            await showDialog<void>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.bluetoothInput),
                content: Text(AppLocalizations.of(context)!.aboutBleInput),
                actions: <Widget>[
                  ElevatedButton(
                    child: Text((AppLocalizations.of(context)!.btnConfirm)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  /// Build widget for 'adapter ready & discovering devices from bluetooth' state
  Widget _buildActive(BuildContext context) {
    _bluetoothSubscription ??= _bluetoothCubit.stream.listen((state) {
      if (state is BluetoothStateReady) {
        logger.finest('_bluetoothSubscription.listen: state=$state');
      } else {
        logger.finer('_bluetoothSubscription.listen: state=$state, calling _returnToIdle');
        _returnToIdle();
      }
    });

    final settings = context.watch<Settings>();
    _deviceScanCubit ??= widget.deviceScanCubit?.call() ?? DeviceScanCubit(
      manager: widget.manager,
      settings: settings,
    );

    return BlocBuilder<DeviceScanCubit, DeviceScanState>(
      bloc: _deviceScanCubit,
      builder: (context, DeviceScanState state) {
        logger.finer('DeviceScanCubit.builder deviceScanState: $state');
        const SizeChangedLayoutNotification().dispatch(context);
        return switch(state) {
          DeviceListLoading() => DeviceScanPlaceholder(
            onClosed: _returnToIdle,
            deviceName: settings.knownBleDev.length == 1
                ? settings.knownBleDev.first
                : null,
          ),
          DeviceListAvailable() => DeviceSelection(
            scanResults: state.devices,
            otherDevices: state.otherDevices,
            onAccepted: (dev) => _deviceScanCubit!.acceptDevice(dev),
          ),
          SingleDeviceAvailable() => DeviceSelection(
            scanResults: [ state.device ],
            onAccepted: (dev) => _deviceScanCubit!.acceptDevice(dev),
          ),
          DeviceSelected() => _buildReadDevice(state)
        };
      },
    );
  }

  /// Build widget for 'reading characteristic value from bluetooth' state
  Widget _buildReadDevice(DeviceSelected selected) {
    logger.finer('_buildReadDevice: state: $selected');
    return BlocConsumer<BleReadCubit, BleReadState>(
      bloc: () {
        _deviceReadCubit = widget.bleReadCubit?.call() ?? selected.readCubit;
        return _deviceReadCubit;
      }(),
      listener: (BuildContext context, BleReadState state) {
        final bluetoothImportMode = context.read<Settings>().bluetoothImportMode;
        if (state is BleReadSuccess) {
          if (bluetoothImportMode.isAutomatic) {
            if (!hasImported) {
              setState(() => hasImported = true);
              unawaited(_importMeasurements([state.data]));
            }
          } else {
            widget.onMeasurement(state.data.asBloodPressureRecord());
            setState(() => _finishedData = state.data);
          }
        } else if (state is BleReadMultiple && bluetoothImportMode.isAutomatic && !hasImported) {
          setState(() => hasImported = true);
          unawaited(_importMeasurements(
            bluetoothImportMode == BluetoothMeasurementImportMode.all
                ? state.data
                : [state.data.first],
          ));
        }
      },
      builder: (BuildContext context, BleReadState state) {
        logger.finer('BleReadCubit.builder: $state');
        const SizeChangedLayoutNotification().dispatch(context);
        final bluetoothImportMode = context.watch<Settings>().bluetoothImportMode;
        return switch (state) {
          BleReadInProgress() => DeviceConnectingPlaceholder(
            onClosed: _returnToIdle,
            deviceName: selected.readCubit.deviceName,
          ),
          BleReadFailure() => MeasurementFailure(
            onTap: _returnToIdle,
            reason: state.reason,
          ),
          BleReadMultiple() when bluetoothImportMode.isAutomatic =>
            _buildMainCard(context, child: const CircularProgressIndicator()),
          BleReadSuccess() when bluetoothImportMode.isAutomatic =>
            _buildMainCard(context, child: const CircularProgressIndicator()),
          BleReadMultiple() => MeasurementMultiple(
            onClosed: _returnToIdle,
            onSelect: (data) => _deviceReadCubit!.useMeasurement(data),
            onSelectAll: (data) {
              widget.onAllMeasurements(
                data.map((e) => e.asBloodPressureRecord()).toList(),
              );
              _returnToIdle();
            },
            measurements: state.data,
          ),
          BleReadSuccess() => MeasurementSuccess(
            onTap: _returnToIdle,
            data: state.data,
          ),
        };
      },
    );
  }

  Widget _buildMainCard(BuildContext context, {
    required Widget child,
    Widget? title,
  }) => InputCard(
    onClosed: _returnToIdle,
    title: title,
    child: child,
  );

  /// Import measurements without letting the user review them first.
  Future<void> _importMeasurements(List<BleMeasurementData> data) async {
    List<BleMeasurementData> incoming;
    try {
      final saved = await context.read<BloodPressureRepository>().get(DateRange.all());
      incoming = newBleMeasurements(data, saved);
    } on ProviderNotFoundException {
      incoming = newBleMeasurements(data, const []);
    } catch (error, stack) {
      logger.severe('_importMeasurements failed', error, stack);
      if (!mounted) return;
      setState(() {
        hasImported = false;
        _importError = 'Could not read saved measurements: $error';
      });
      return;
    }
    logger.finer('_importMeasurements: count=${incoming.length}');
    if (!mounted || _finishedData != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _finishedData != null) return;
      widget.onAllMeasurements(
        incoming.map((e) => e.asBloodPressureRecord()).toList(),
      );
      _returnToIdle();
    });
  }
}
