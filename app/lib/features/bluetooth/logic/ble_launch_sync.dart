import 'dart:async';

import 'package:blood_pressure_app/features/bluetooth/backend/bluetooth_backend.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/ble_device_filter.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/ble_measurement_duplicates.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/ble_read_cubit.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/bluetooth_cubit.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/characteristics/ble_measurement_data.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/device_scan_cubit.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_weight_data.dart';
import 'package:blood_pressure_app/logging.dart';
import 'package:blood_pressure_app/model/bluetooth_input_mode.dart';
import 'package:blood_pressure_app/model/known_ble_device.dart';
import 'package:blood_pressure_app/model/storage/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:health_data_store/health_data_store.dart';

/// Outcome of a launch-time meter sync.
enum BleLaunchSyncStatus {
  /// Setting off, Bluetooth input disabled, or no saved meter.
  skipped,
  /// Adapter is off, so the meter could not be reached.
  bluetoothOff,
  /// New readings were written to the diary.
  imported,
  /// The meter responded but every reading was already saved.
  upToDate,
  /// Scan, connect, or decode failed.
  failed,
  /// The saved meter did not appear before the scan window ended.
  notFound,
  /// The user left the home screen or dismissed the card.
  cancelled,
}

/// Result of [BleLaunchSync.run].
@immutable
class BleLaunchSyncResult {
  /// Create a launch-sync result.
  const BleLaunchSyncResult({
    required this.status,
    this.count = 0,
    this.receivedCount = 0,
    this.deviceName,
  });

  /// What happened.
  final BleLaunchSyncStatus status;

  /// Number of new readings imported.
  final int count;

  /// Number of readings the meter sent, including duplicates.
  final int receivedCount;

  /// Advertised name of the meter, when known.
  final String? deviceName;

  /// Readings the meter sent that were already in the diary.
  int get duplicateCount => receivedCount > count ? receivedCount - count : 0;
}

/// Live stage of a launch sync, used by the status card.
enum BleLaunchSyncPhase {
  /// Sync has not started.
  idle,
  /// Searching for a saved meter.
  scanning,
  /// A saved meter was found and a connection is opening.
  connecting,
  /// Connected and waiting for stored readings.
  reading,
  /// Filtering duplicates and writing new readings.
  importing,
  /// Finished, failed, or Bluetooth was off.
  done,
}

/// Snapshot of launch-sync progress for the UI.
@immutable
class BleLaunchSyncProgress {
  /// Create a progress snapshot.
  const BleLaunchSyncProgress({
    this.phase = BleLaunchSyncPhase.idle,
    this.deviceName,
    this.deviceCount = 0,
    this.receivedCount = 0,
    this.result,
    this.scanUntil,
    this.lookingForMore = false,
  });

  /// Current stage.
  final BleLaunchSyncPhase phase;

  /// Meter name, when known.
  final String? deviceName;

  /// Saved meters found or synced so far.
  final int deviceCount;

  /// Readings received so far, when known.
  final int receivedCount;

  /// Final outcome, when [phase] is [BleLaunchSyncPhase.done].
  final BleLaunchSyncResult? result;

  /// When the scan window ends, used for the countdown.
  final DateTime? scanUntil;

  /// First meter is already connecting or reading; still looking for extras.
  final bool lookingForMore;

  /// Whether the meter is still being contacted or imported.
  bool get isBusy =>
      phase != BleLaunchSyncPhase.idle && phase != BleLaunchSyncPhase.done;

  /// Whether the AppBar icon and popout can show this snapshot.
  bool get hasVisibleStatus =>
      isBusy
      || (result != null && result!.status != BleLaunchSyncStatus.skipped);
}

/// Connects to a saved meter when the app opens and imports unread measurements.
class BleLaunchSync with TypeLogger {
  /// Create a launch sync using live Bluetooth objects or test doubles.
  BleLaunchSync({
    required this.settings,
    required this.repo,
    this.weightRepo,
    this.manager,
    this.bluetoothCubit,
    this.deviceScanCubit,
    this.scanTimeout = const Duration(minutes: 1),
    this.extraScanTimeout = const Duration(seconds: 10),
    this.readTimeout = const Duration(seconds: 95),
    this.adapterTimeout = const Duration(seconds: 20),
    this.tryParallel = true,
    this.readers,
  });

  /// User settings that gate and configure the sync.
  final Settings settings;

  /// Diary used to drop already-saved readings and persist new ones.
  final BloodPressureRepository repo;

  /// Optional diary for body-weight readings from a saved scale.
  final BodyweightRepository? weightRepo;

  /// Backend used when cubits are created here.
  final BluetoothManager? manager;

  /// Optional [BluetoothCubit] factory for tests.
  final BluetoothCubit Function()? bluetoothCubit;

  /// Optional [DeviceScanCubit] factory for tests.
  final DeviceScanCubit Function()? deviceScanCubit;

  /// How long to wait for a saved meter to appear.
  final Duration scanTimeout;

  /// Extra scan after the first meter is already connecting or reading.
  final Duration extraScanTimeout;

  /// How long to wait for the meter to finish sending readings.
  final Duration readTimeout;

  /// How long to wait for the adapter to become ready or turn off.
  final Duration adapterTimeout;

  /// When more than one meter is found, try to read them at the same time.
  ///
  /// If a second connection fails while another is active, remaining meters
  /// are retried one after another (older phones often cannot hold two GATT
  /// links).
  final bool tryParallel;

  /// Optional readers for tests, used instead of creating cubits from scan.
  final List<BleReadCubit> Function()? readers;

  /// Live stage shown by the launch-sync card.
  final ValueNotifier<BleLaunchSyncProgress> progress =
      ValueNotifier(const BleLaunchSyncProgress());

  /// Whether a launch sync is currently connecting or importing.
  static bool isRunning = false;

  /// The in-flight launch sync, if any.
  static BleLaunchSync? active;

  static Completer<void>? _idle;

  Completer<void>? _abort;

  static bool _completedThisSession = false;

  bool get _isCancelled => _abort?.isCompleted ?? false;

  /// Completes when [active] finishes tearing down.
  static Future<void> waitUntilIdle() async {
    final idle = _idle;
    if (idle == null || idle.isCompleted) return;
    await idle.future;
  }

  /// Allow another launch sync, used by tests.
  @visibleForTesting
  static void resetSession() {
    isRunning = false;
    active = null;
    _completedThisSession = false;
    if (_idle != null && !_idle!.isCompleted) {
      _idle!.complete();
    }
    _idle = null;
  }

  /// Let a later [run] start after this process already finished one attempt.
  static void allowRetry() {
    _completedThisSession = false;
  }

  /// Run at most once per process unless [resetSession] or [allowRetry] is called.
  Future<BleLaunchSyncResult> run() async {
    if (_completedThisSession || isRunning) {
      return const BleLaunchSyncResult(status: BleLaunchSyncStatus.skipped);
    }
    if (!settings.syncBluetoothOnLaunch
        || settings.bleInput == BluetoothInputMode.disabled
        || _autoSyncDevices.isEmpty) {
      return const BleLaunchSyncResult(status: BleLaunchSyncStatus.skipped);
    }

    isRunning = true;
    active = this;
    _idle = Completer<void>();
    _abort = Completer<void>();
    _emit(BleLaunchSyncPhase.scanning);
    try {
      final result = await _sync();
      _emit(
        BleLaunchSyncPhase.done,
        result: result,
        deviceName: result.deviceName,
        deviceCount: progress.value.deviceCount,
        receivedCount: result.receivedCount,
      );
      return result;
    } catch (error, stack) {
      logger.severe('Launch meter sync failed', error, stack);
      const failed = BleLaunchSyncResult(status: BleLaunchSyncStatus.failed);
      _emit(BleLaunchSyncPhase.done, result: failed);
      return failed;
    } finally {
      isRunning = false;
      if (identical(active, this)) active = null;
      if (_idle != null && !_idle!.isCompleted) {
        _idle!.complete();
      }
      if (!_isCancelled) {
        _completedThisSession = true;
      }
    }
  }

  String? get _fallbackName => settings.knownBleDev.length == 1
      ? settings.knownBleDev.first.displayName
      : null;

  String? _joinedNames(Iterable<String?> names) {
    final found = names
        .map((name) => name?.trim())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList();
    if (found.isEmpty) return _fallbackName;
    return found.join(', ');
  }

  /// Stop a scan or read that is still waiting.
  void cancel() {
    if (_abort != null && !_abort!.isCompleted) {
      _abort!.complete();
    }
  }

  void _emit(
    BleLaunchSyncPhase phase, {
    String? deviceName,
    int deviceCount = 0,
    int receivedCount = 0,
    BleLaunchSyncResult? result,
    bool lookingForMore = false,
    DateTime? scanUntil,
  }) {
    progress.value = BleLaunchSyncProgress(
      phase: phase,
      deviceName: deviceName ?? _fallbackName,
      deviceCount: deviceCount,
      receivedCount: receivedCount,
      result: result,
      lookingForMore: lookingForMore,
      scanUntil: scanUntil ??
          (lookingForMore
              ? DateTime.now().add(extraScanTimeout)
              : phase == BleLaunchSyncPhase.scanning
                  ? DateTime.now().add(scanTimeout)
                  : null),
    );
  }

  Future<BleLaunchSyncResult> _sync() async {
    final resolvedManager = manager ??
        (bluetoothCubit == null && deviceScanCubit == null && readers == null
            ? BluetoothManager.create()
            : null);
    final bluetooth = bluetoothCubit?.call()
        ?? BluetoothCubit(manager: resolvedManager!);
    DeviceScanCubit? scan;
    final opened = <BleReadCubit>[];
    try {
      final adapter = await _waitForAdapter(bluetooth);
      if (adapter is BluetoothStateDisabled) {
        return const BleLaunchSyncResult(status: BleLaunchSyncStatus.bluetoothOff);
      }
      if (adapter is! BluetoothStateReady) {
        return const BleLaunchSyncResult(status: BleLaunchSyncStatus.failed);
      }

      _emit(BleLaunchSyncPhase.scanning);
      final List<_DeviceRead> reads;
      if (readers != null) {
        final targets = [
          for (final read in readers!()) _SyncTarget.reader(read),
        ];
        if (targets.isEmpty) {
          return BleLaunchSyncResult(
            status: _isCancelled
                ? BleLaunchSyncStatus.cancelled
                : BleLaunchSyncStatus.notFound,
          );
        }
        final names = _joinedNames(targets.map((target) => target.name));
        _emit(
          BleLaunchSyncPhase.connecting,
          deviceName: names,
          deviceCount: targets.length,
        );
        _emit(
          BleLaunchSyncPhase.reading,
          deviceName: names,
          deviceCount: targets.length,
        );
        reads = await _readTargets(targets, opened);
      } else {
        scan = deviceScanCubit?.call()
            ?? DeviceScanCubit(
              manager: resolvedManager!,
              settings: settings,
              autoRead: false,
            );
        reads = await _findAndRead(scan, opened);
      }
      if (reads.isEmpty) {
        return BleLaunchSyncResult(
          status: _isCancelled
              ? BleLaunchSyncStatus.cancelled
              : BleLaunchSyncStatus.notFound,
        );
      }

      final names = _joinedNames(reads.map((read) => read.name));
      if (_isCancelled) {
        return BleLaunchSyncResult(
          status: BleLaunchSyncStatus.cancelled,
          deviceName: names,
        );
      }
      final measurements = [
        for (final read in reads)
          if (read.measurements != null) ...read.measurements!,
      ];
      final weights = [
        for (final read in reads)
          if (read.weights != null) ...read.weights!,
      ];
      final synced = reads.where((read) => read.ok).length;
      if (synced == 0) {
        return BleLaunchSyncResult(
          status: BleLaunchSyncStatus.failed,
          deviceName: names,
        );
      }

      final receivedCount = measurements.length + weights.length;
      _emit(
        BleLaunchSyncPhase.importing,
        deviceName: names,
        deviceCount: synced,
        receivedCount: receivedCount,
      );
      final saved = await repo.get(DateRange.all());
      final incoming = newBleMeasurements(measurements, saved);
      for (final measurement in incoming) {
        await repo.add(measurement.asBloodPressureRecord());
      }
      var importedWeights = 0;
      if (weightRepo != null && weights.isNotEmpty) {
        final savedWeights = await weightRepo!.get(DateRange.all());
        final incomingWeights = newBleWeights(weights, savedWeights);
        final upgrades = bleWeightsToUpgrade(weights, savedWeights);
        for (final weight in incomingWeights) {
          await weightRepo!.add(weight.asBodyweightRecord());
        }
        for (final (old, incoming) in upgrades) {
          await weightRepo!.remove(old);
          await weightRepo!.add(incoming.asBodyweightRecord());
        }
        importedWeights = incomingWeights.length + upgrades.length;
        if (importedWeights > 0) {
          settings.weightInput = true;
        }
      }
      for (final read in reads) {
        final device = read.device;
        if (device != null && read.weights != null) {
          _rememberDevice(device);
        }
      }
      final imported = incoming.length + importedWeights;
      return BleLaunchSyncResult(
        status: imported == 0
            ? BleLaunchSyncStatus.upToDate
            : BleLaunchSyncStatus.imported,
        count: imported,
        receivedCount: receivedCount,
        deviceName: names,
      );
    } finally {
      for (final read in opened) {
        await read.close();
      }
      await scan?.close();
      await bluetooth.close();
    }
  }

  Future<BluetoothState> _waitForAdapter(BluetoothCubit cubit) async {
    if (_isSettledAdapter(cubit.state)) return cubit.state;
    final abort = _abort;
    try {
      return await Future.any<BluetoothState>([
        cubit.stream.firstWhere(_isSettledAdapter),
        Future<BluetoothState>.delayed(adapterTimeout, () => cubit.state),
        if (abort != null) abort.future.then((_) => cubit.state),
      ]);
    } catch (_) {
      return cubit.state;
    }
  }

  bool _isSettledAdapter(BluetoothState state) =>
      state is BluetoothStateReady
      || state is BluetoothStateDisabled
      || state is BluetoothStateUnfeasible;

  Future<T?> _waitOrAbort<T>(Future<T> future, Duration timeout) async {
    final abort = _abort;
    try {
      return await Future.any<T?>([
        future.then<T?>((value) => value),
        Future<T?>.delayed(timeout, () => null),
        if (abort != null) abort.future.then((_) => null),
      ]);
    } catch (_) {
      return null;
    }
  }

  List<KnownBleDevice> get _autoSyncDevices =>
      settings.knownBleDev.where((device) => device.autoSync).toList();

  /// Extra scan and parallel reads only make sense with more than one saved meter.
  bool get _hasMultipleSavedDevices => settings.knownBleDev.length > 1;

  bool _isKnown(BluetoothDevice device) =>
      _autoSyncDevices.any((known) => known.matches(device.deviceId, device.name));

  void _rememberDevice(BluetoothDevice device) {
    final list = settings.knownBleDev.toList();
    if (list.any((known) => known.matches(device.deviceId, device.name))) {
      settings.knownBleDev = [
        for (final known in list)
          if (known.matches(device.deviceId, device.name))
            known.copyWith(id: device.deviceId, name: device.name)
          else
            known,
      ];
      return;
    }
    list.add(KnownBleDevice(id: device.deviceId, name: device.name));
    settings.knownBleDev = list;
  }

  Iterable<BluetoothDevice> _knownIn(DeviceScanState state) => switch (state) {
    SingleDeviceAvailable(:final device) =>
      _isKnown(device) ? [device] : const <BluetoothDevice>[],
    DeviceListAvailable(:final devices, :final otherDevices) =>
      [...devices, ...otherDevices].where(_isKnown),
    _ => const <BluetoothDevice>[],
  };

  Future<List<_DeviceRead>> _findAndRead(
    DeviceScanCubit scan,
    List<BleReadCubit> opened,
  ) async {
    final found = <String, _SyncTarget>{};
    final startedKeys = <String>{};
    final parallelTargets = <_SyncTarget>[];
    final inFlight = <Future<_DeviceRead>>[];
    final queued = <_SyncTarget>[];
    var startChain = Future<void>.value();

    void consider(DeviceScanState state) {
      if (state is DeviceSelected) {
        found[state.readCubit.deviceName ?? 'selected'] =
            _SyncTarget.reader(state.readCubit);
        return;
      }
      for (final device in _knownIn(state)) {
        found[device.deviceId] = _SyncTarget.device(device);
      }
    }

    bool expectingScale() =>
        _autoSyncDevices.any((device) => isEufyP1ScaleName(device.name));
    bool hasExpectedScale() =>
        !expectingScale()
        || found.values.any((target) => isEufyP1ScaleName(target.name));
    bool hasAllKnown() =>
        _autoSyncDevices.isNotEmpty && found.length >= _autoSyncDevices.length;
    bool wantMore() =>
        _hasMultipleSavedDevices && (!hasAllKnown() || !hasExpectedScale());

    String? names() => _joinedNames(found.values.map((target) => target.name));

    Future<void> startNew({required bool resumeAfter}) async {
      final newcomers = [
        for (final entry in found.entries)
          if (!startedKeys.contains(entry.key)) entry,
      ];
      if (newcomers.isEmpty) return;
      if (resumeAfter) {
        await scan.pauseScan();
      }
      for (final entry in newcomers) {
        startedKeys.add(entry.key);
        final target = entry.value;
        if (parallelTargets.isEmpty || (tryParallel && _hasMultipleSavedDevices)) {
          parallelTargets.add(target);
          inFlight.add(_readTarget(target, opened));
        } else {
          queued.add(target);
        }
      }
      if (resumeAfter && wantMore() && !_isCancelled) {
        await scan.resumeScan();
      }
    }

    Future<void> enqueueStart({required bool resumeAfter}) {
      startChain = startChain.then((_) => startNew(resumeAfter: resumeAfter));
      return startChain;
    }

    consider(scan.state);
    if (found.isEmpty && scan.state is! DeviceSelected && !_isCancelled) {
      final first = Completer<void>();
      final subscription = scan.stream.listen((state) {
        consider(state);
        if (found.isNotEmpty && !first.isCompleted) first.complete();
      });
      await _waitOrAbort(first.future, scanTimeout);
      await subscription.cancel();
    }
    if (found.isEmpty) {
      if (!_isCancelled) {
        logger.info('Launch meter sync timed out waiting for a saved device');
      }
      return [];
    }

    await scan.pauseScan();
    _emit(
      BleLaunchSyncPhase.connecting,
      deviceName: names(),
      deviceCount: found.length,
      lookingForMore: wantMore(),
    );
    _emit(
      BleLaunchSyncPhase.reading,
      deviceName: names(),
      deviceCount: found.length,
      lookingForMore: wantMore(),
    );
    await startNew(resumeAfter: false);
    if (wantMore() && !_isCancelled) {
      await scan.resumeScan();
      final extraUntil = DateTime.now().add(extraScanTimeout);
      _emit(
        BleLaunchSyncPhase.reading,
        deviceName: names(),
        deviceCount: found.length,
        lookingForMore: true,
        scanUntil: extraUntil,
      );
      final extraDone = Completer<void>();
      final extraSub = scan.stream.listen((state) {
        consider(state);
        unawaited(enqueueStart(resumeAfter: true).then((_) {
          _emit(
            BleLaunchSyncPhase.reading,
            deviceName: names(),
            deviceCount: found.length,
            lookingForMore: wantMore(),
            scanUntil: extraUntil,
          );
          if (!wantMore() && !extraDone.isCompleted) extraDone.complete();
        }));
      });
      await _waitOrAbort(extraDone.future, extraScanTimeout);
      await extraSub.cancel();
      await startChain;
      await scan.pauseScan();
      _emit(
        BleLaunchSyncPhase.reading,
        deviceName: names(),
        deviceCount: found.length,
      );
    }

    if (inFlight.isEmpty) return [];
    final firstPass = await Future.wait(inFlight);
    if (_isCancelled) return firstPass;

    final results = <_DeviceRead>[];
    final succeeded = firstPass.where((read) => read.ok).length;
    if (tryParallel
        && firstPass.length > 1
        && succeeded > 0
        && succeeded < firstPass.length) {
      logger.info(
        'Parallel meter sync failed for ${firstPass.length - succeeded} '
        'device(s); retrying one at a time',
      );
      for (final (index, read) in firstPass.indexed) {
        if (read.ok) {
          results.add(read);
          continue;
        }
        if (_isCancelled) {
          results.add(read);
          continue;
        }
        final target = parallelTargets[index];
        if (target.reader == null && read.cubit != null) {
          await read.cubit!.close();
          opened.remove(read.cubit);
        }
        results.add(await _readTarget(target, opened));
      }
    } else {
      results.addAll(firstPass);
    }

    for (final target in queued) {
      if (_isCancelled) break;
      results.add(await _readTarget(target, opened));
    }
    return results;
  }

  Future<List<_DeviceRead>> _readTargets(
    List<_SyncTarget> targets,
    List<BleReadCubit> opened,
  ) async {
    if (targets.length == 1 || !tryParallel || !_hasMultipleSavedDevices) {
      return [
        for (final target in targets) await _readTarget(target, opened),
      ];
    }

    final firstPass = await Future.wait([
      for (final target in targets) _readTarget(target, opened),
    ]);
    if (_isCancelled) return firstPass;

    final succeeded = firstPass.where((read) => read.ok).length;
    if (succeeded == 0 || succeeded == firstPass.length) return firstPass;

    logger.info(
      'Parallel meter sync failed for ${firstPass.length - succeeded} '
      'device(s); retrying one at a time',
    );
    final retried = <_DeviceRead>[];
    for (final (index, read) in firstPass.indexed) {
      if (read.ok) {
        retried.add(read);
        continue;
      }
      if (_isCancelled) {
        retried.add(read);
        continue;
      }
      final target = targets[index];
      if (target.reader == null && read.cubit != null) {
        await read.cubit!.close();
        opened.remove(read.cubit);
      }
      retried.add(await _readTarget(target, opened));
    }
    return retried;
  }

  Future<_DeviceRead> _readTarget(
    _SyncTarget target,
    List<BleReadCubit> opened,
  ) async {
    final read = target.reader ?? BleReadCubit(
      device: target.device!.source.peripheral,
      cm: target.device!.manager,
      deviceName: target.device!.name,
    );
    if (!opened.contains(read)) opened.add(read);
    if (read.state is BleReadInProgress) {
      unawaited(read.takeMeasurement());
    }
    final result = await _waitForRead(read);
    return _DeviceRead(
      name: read.deviceName ?? target.name,
      device: target.device,
      measurements: result.measurements,
      weights: result.weights,
      cubit: read,
    );
  }

  Future<({List<BleMeasurementData>? measurements, List<BleWeightData>? weights})>
      _waitForRead(BleReadCubit read) async {
    BleReadState state = read.state;
    if (state is! BleReadSuccess
        && state is! BleReadMultiple
        && state is! BleReadWeightSuccess
        && state is! BleReadFailure) {
      if (_isCancelled) {
        return (measurements: null, weights: null);
      }
      final next = await _waitOrAbort(
        read.stream.firstWhere((value) =>
            value is BleReadSuccess
            || value is BleReadMultiple
            || value is BleReadWeightSuccess
            || value is BleReadFailure),
        readTimeout,
      );
      if (next == null) {
        if (!_isCancelled) {
          logger.info('Launch meter sync timed out waiting for measurements');
        }
        return (measurements: null, weights: null);
      }
      state = next;
    }
    return switch (state) {
      BleReadSuccess(:final data) => (measurements: [data], weights: null),
      BleReadMultiple(:final data) => (measurements: data, weights: null),
      BleReadWeightSuccess(:final data) => (measurements: null, weights: [data]),
      BleReadFailure() => (measurements: null, weights: null),
      BleReadInProgress() => (measurements: null, weights: null),
    };
  }
}

class _SyncTarget {
  const _SyncTarget.reader(this.reader) : device = null;
  const _SyncTarget.device(this.device) : reader = null;

  final BleReadCubit? reader;
  final BluetoothDevice? device;

  String? get name => reader?.deviceName ?? device?.name;
}

class _DeviceRead {
  const _DeviceRead({
    required this.name,
    this.device,
    this.measurements,
    this.weights,
    this.cubit,
  });

  final String? name;
  final BluetoothDevice? device;
  final List<BleMeasurementData>? measurements;
  final List<BleWeightData>? weights;
  final BleReadCubit? cubit;

  bool get ok => measurements != null || weights != null;
}
