import 'package:blood_pressure_app/features/health_connect/sync_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

void main() {
  test('skips the system sheet when write access is already granted', () async {
    final health = _FakeHealth(has: true);

    expect(await health.requestPermissionsIfMissing(), isTrue);
    expect(health.requestCount, 0);
  });

  test('shows the system sheet when write access is missing', () async {
    final health = _FakeHealth(has: false);

    expect(await health.requestPermissionsIfMissing(), isTrue);
    expect(health.requestCount, 1);
  });

  test('shows the system sheet when the availability check throws', () async {
    final health = _FakeHealth(hasError: UnsupportedError('unavailable'));

    expect(await health.requestPermissionsIfMissing(), isTrue);
    expect(health.requestCount, 1);
  });
}

class _FakeHealth extends Fake implements Health {
  _FakeHealth({this.has = false, this.hasError});

  final bool has;
  final Object? hasError;
  int requestCount = 0;

  @override
  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    if (hasError != null) throw hasError!;
    return has;
  }

  @override
  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    requestCount += 1;
    return true;
  }
}
