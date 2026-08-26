import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

abstract class SyncModel extends ChangeNotifier {
  bool get syncing;

  double get progress;

  Future<void> sync();
}

extension RequestPermissions on Health {
  /// Requests each [types] with [permission] if not already available.
  ///
  /// Requests all permissions used by the app if not specified.
  Future<bool> requestPermissionsIfMissing([
    List<HealthDataType>? types,
    HealthDataAccess permission = HealthDataAccess.READ_WRITE,
  ]) async {
    types ??= [
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      HealthDataType.WEIGHT,
    ];

    final permissions = List.filled(types.length, permission);
    try {
      final canWrite = await hasPermissions(
        types,
        permissions: permissions,
      ) ?? false;
      if (canWrite) return true;
    } catch (_) {
      // Availability checks can throw before the system sheet is shown.
    }
    return requestAuthorization(types, permissions: permissions);
  }
}
