import 'dart:async';

import 'package:blood_pressure_app/features/bluetooth/logic/ble_read_cubit.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/bluetooth_cubit.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/device_scan_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [BluetoothCubit] for tests. Avoids Mockito stubs on [state].
class StubBluetoothCubit extends Fake implements BluetoothCubit {
  StubBluetoothCubit([BluetoothState? initial])
      : state = initial ?? BluetoothStateInitial();

  @override
  BluetoothState state;
  final _controller = StreamController<BluetoothState>.broadcast();

  @override
  Stream<BluetoothState> get stream => _controller.stream;

  @override
  bool get isClosed => false;

  void add(BluetoothState value) {
    state = value;
    _controller.add(value);
  }

  @override
  Future<bool?> enableBluetooth() async => true;

  @override
  void forceRefresh() {}

  @override
  Future<void> close() async {
    await _controller.close();
  }
}

/// In-memory [DeviceScanCubit] for tests.
class StubDeviceScanCubit extends Fake implements DeviceScanCubit {
  StubDeviceScanCubit([DeviceScanState? initial])
      : state = initial ?? DeviceListLoading();

  @override
  DeviceScanState state;
  final _controller = StreamController<DeviceScanState>.broadcast();

  @override
  Stream<DeviceScanState> get stream => _controller.stream;

  @override
  bool get isClosed => false;

  @override
  Future<void> pauseScan() async {}

  @override
  Future<void> resumeScan() async {}

  void add(DeviceScanState value) {
    state = value;
    _controller.add(value);
  }

  @override
  Future<void> close() async {
    await _controller.close();
  }
}

/// In-memory [BleReadCubit] for tests.
class StubBleReadCubit extends Fake implements BleReadCubit {
  StubBleReadCubit([this.deviceName, BleReadState? initial])
      : state = initial ?? BleReadInProgress();

  @override
  final String? deviceName;

  @override
  BleReadState state;
  final _controller = StreamController<BleReadState>.broadcast();

  @override
  Stream<BleReadState> get stream => _controller.stream;

  @override
  bool get isClosed => false;

  void add(BleReadState value) {
    state = value;
    _controller.add(value);
  }

  @override
  Future<void> close() async {
    await _controller.close();
  }
}

/// Stubs [cubit.state] / [cubit.stream] the way `bloc_test`'s `whenListen` did.
void whenListen<S>(
  dynamic cubit,
  Stream<S> stream, {
  required S initialState,
}) {
  if (cubit is StubBluetoothCubit) {
    cubit.state = initialState as BluetoothState;
    stream.listen((value) => cubit.add(value as BluetoothState));
    return;
  }
  if (cubit is StubDeviceScanCubit) {
    cubit.state = initialState as DeviceScanState;
    stream.listen((value) => cubit.add(value as DeviceScanState));
    return;
  }
  if (cubit is StubBleReadCubit) {
    cubit.state = initialState as BleReadState;
    stream.listen((value) => cubit.add(value as BleReadState));
    return;
  }
  throw StateError(
    'whenListen expected a StubBluetoothCubit, StubDeviceScanCubit, '
    'or StubBleReadCubit, got ${cubit.runtimeType}',
  );
}
