import 'package:blood_pressure_app/features/bluetooth/logic/characteristics/ble_measurement_data.dart';

/// Outcome of a [BleDeviceProfile.read].
sealed class BleDeviceReadResult {
  const BleDeviceReadResult();
}

/// One or more blood-pressure measurements.
class BleBloodPressureRead extends BleDeviceReadResult {
  /// Create a successful blood-pressure read.
  const BleBloodPressureRead(this.measurements);

  /// Decoded measurements, oldest first when the device sent a dump.
  final List<BleMeasurementData> measurements;
}

/// The profile could not read the device.
class BleDeviceReadFailure extends BleDeviceReadResult {
  /// Create a failed read.
  const BleDeviceReadFailure(this.reason);

  /// Why the read failed.
  final String reason;
}
