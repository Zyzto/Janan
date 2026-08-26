import 'dart:io';

import 'package:blood_pressure_app/core/repository/powersync_blood_pressure_repository.dart';
import 'package:blood_pressure_app/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart';

import '../domain/blood_pressure_record_test.dart';
import '../powersync_probe.dart';

void main() {
  bool available = false;
  PowerSyncDatabase? db;
  String? dbPath;

  setUpAll(() async {
    available = await powerSyncAvailable();
    if (!available) return;
    final opened = await openTempHealthDb();
    db = opened.$1;
    dbPath = opened.$2;
  });

  tearDownAll(() async {
    final opened = db;
    if (opened == null) return;
    await opened.close();
    final path = dbPath;
    if (path != null) {
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
  });

  test('stores and returns records', () async {
    if (!available) return;
    final repo = PowerSyncBloodPressureRepository(db!);
    final r1 = mockRecord(time: 50000, sys: 123);
    final r2 = mockRecord(time: 80000, sys: 456, dia: 457, pul: 458);
    final r3 = mockRecord(time: 20000, sys: 788, pul: 789);
    await repo.add(r1);
    await repo.add(r2);
    await repo.add(r3);

    final values = await repo.get(DateRange(
      start: DateTime.fromMillisecondsSinceEpoch(20000),
      end: DateTime.fromMillisecondsSinceEpoch(80000),
    ));
    expect(values, hasLength(3));
    expect(values, containsAll([r1, r2, r3]));
  });

  test('removes records', () async {
    if (!available) return;
    final repo = PowerSyncBloodPressureRepository(db!);
    final r1 = mockRecord(time: 100000, sys: 456, dia: 457, pul: 458);
    await repo.add(r1);
    expect(await repo.get(DateRange.all()), contains(r1));
    await repo.remove(r1);
    expect(await repo.get(DateRange(
      start: DateTime.fromMillisecondsSinceEpoch(0),
      end: DateTime.fromMillisecondsSinceEpoch(200000),
    )), isNot(contains(r1)));
  });
}
