part of 'device_scan_cubit.dart';

/// Search of bluetooth devices that meet some criteria.
@immutable
sealed class DeviceScanState {}

/// Searching for devices or a reason they are not available.
class DeviceListLoading extends DeviceScanState {}

/// A device has been selected, either automatically or by the user.
class DeviceSelected extends DeviceScanState {
  /// Indicate that a device has been selected.
  DeviceSelected(this.readCubit);

  /// The selected device.
  final BleReadCubit readCubit;
}

/// Multiple unrecognized devices.
class DeviceListAvailable extends DeviceScanState {
  /// Indicate that unrecognized devices have been found.
  DeviceListAvailable(this.devices, {this.otherDevices = const []});

  /// Likely blood-pressure devices.
  final List<BluetoothDevice> devices;

  /// Other nearby devices hidden behind a fallback expander.
  final List<BluetoothDevice> otherDevices;
}

/// One unrecognized device has been found.
///
/// While not technically correct, this can be understood as a connection
/// request the user has to accept.
class SingleDeviceAvailable extends DeviceScanState {
  /// Indicate that one unrecognized device has been found.
  SingleDeviceAvailable(this.device);

  /// The only found device.
  final BluetoothDevice device;
}
