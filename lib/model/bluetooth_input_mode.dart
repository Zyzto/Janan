import 'package:easy_localization/easy_localization.dart';

/// Different modes for the bluetooth input field.
enum BluetoothInputMode {
  /// No bluetooth input.
  disabled,
  /// Ultra engine (`flutter_blue_ultra`) measurement input.
  oldBluetoothInput,
  /// BLE engine (`bluetooth_low_energy`) measurement input.
  newBluetoothInputCrossPlatform;

  /// Create a [BluetoothInputMode.deserialize]able number.
  int get serialized => switch(this) {
    BluetoothInputMode.disabled => 0,
    BluetoothInputMode.oldBluetoothInput => 1,
    BluetoothInputMode.newBluetoothInputCrossPlatform => 3,
  };

  /// Try to create an object from [serialized] form.
  static BluetoothInputMode? deserialize(int? value) => switch (value) {
    0 => BluetoothInputMode.disabled,
    1 => BluetoothInputMode.oldBluetoothInput,
    2 || 3 => BluetoothInputMode.newBluetoothInputCrossPlatform,
    _ => null,
  };

  /// Determine the matching localization.
  String localize() => switch(this) {
    BluetoothInputMode.disabled => 'disabled'.tr(),
    BluetoothInputMode.oldBluetoothInput => 'legacyBluetoothInput'.tr(),
    BluetoothInputMode.newBluetoothInputCrossPlatform => 'stableBluetoothInput'.tr(),
  };
}
