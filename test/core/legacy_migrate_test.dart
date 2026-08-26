import 'dart:io';

import 'package:blood_pressure_app/core/database/health_database.dart';
import 'package:blood_pressure_app/core/repository/powersync_blood_pressure_repository.dart';
import 'package:blood_pressure_app/core/repository/powersync_note_repository.dart';
import 'package:blood_pressure_app/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'powersync_probe.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('migrates a legacy bp.db into health.db', () async {
    if (!await powerSyncAvailable()) return;

    final dir = Directory.systemTemp.createTempSync('janan_migrate_');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    final legacyPath = p.join(dir.path, HealthDatabase.legacyFileName);
    final sqlite = await openDatabase(legacyPath);
    await sqlite.execute(
      'CREATE TABLE "Timestamps" ('
      '"entryID" INTEGER NOT NULL UNIQUE,'
      '"timestampUnixS" INTEGER NOT NULL,'
      'PRIMARY KEY("entryID"));',
    );
    await sqlite.execute(
      'CREATE TABLE "Systolic" ('
      '"entryID" INTEGER NOT NULL,'
      '"sys" REAL,'
      'PRIMARY KEY("entryID"));',
    );
    await sqlite.execute(
      'CREATE TABLE "Diastolic" ('
      '"entryID" INTEGER NOT NULL,'
      '"dia" REAL,'
      'PRIMARY KEY("entryID"));',
    );
    await sqlite.execute(
      'CREATE TABLE "Pulse" ('
      '"entryID" INTEGER NOT NULL,'
      '"pul" INTEGER,'
      'PRIMARY KEY("entryID"));',
    );
    await sqlite.insert('Timestamps', {'entryID': 1, 'timestampUnixS': 50});
    await sqlite.insert('Systolic', {'entryID': 1, 'sys': Pressure.mmHg(123).kPa});
    await sqlite.insert('Diastolic', {'entryID': 1, 'dia': Pressure.mmHg(80).kPa});
    await sqlite.insert('Pulse', {'entryID': 1, 'pul': 70});
    await sqlite.close();

    final db = await HealthDatabase.open(directory: dir.path);
    addTearDown(db.close);

    final records = await PowerSyncBloodPressureRepository(db).get(DateRange.all());
    expect(records, hasLength(1));
    expect(records.first.sys?.mmHg, 123);
    expect(records.first.dia?.mmHg, 80);
    expect(records.first.pul, 70);
    expect(File(p.join(dir.path, HealthDatabase.legacyBackupName)).existsSync(), isTrue);
    expect(File(legacyPath).existsSync(), isFalse);
  });

  test('retries leftover bp.db when health.db already has blood pressure', () async {
    if (!await powerSyncAvailable()) return;

    final dir = Directory.systemTemp.createTempSync('janan_migrate_retry_');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    final health = await HealthDatabase.open(directory: dir.path);
    await PowerSyncBloodPressureRepository(health).add(BloodPressureRecord(
      time: DateTimeS.fromSecondsSinceEpoch(50),
      sys: Pressure.mmHg(123),
      dia: Pressure.mmHg(80),
      pul: 70,
    ));
    await health.close();

    final legacyPath = p.join(dir.path, HealthDatabase.legacyFileName);
    final sqlite = await openDatabase(legacyPath);
    await sqlite.execute(
      'CREATE TABLE "Timestamps" ('
      '"entryID" INTEGER NOT NULL UNIQUE,'
      '"timestampUnixS" INTEGER NOT NULL,'
      'PRIMARY KEY("entryID"));',
    );
    await sqlite.execute(
      'CREATE TABLE "Systolic" ('
      '"entryID" INTEGER NOT NULL,'
      '"sys" REAL,'
      'PRIMARY KEY("entryID"));',
    );
    await sqlite.execute(
      'CREATE TABLE "Diastolic" ('
      '"entryID" INTEGER NOT NULL,'
      '"dia" REAL,'
      'PRIMARY KEY("entryID"));',
    );
    await sqlite.execute(
      'CREATE TABLE "Pulse" ('
      '"entryID" INTEGER NOT NULL,'
      '"pul" INTEGER,'
      'PRIMARY KEY("entryID"));',
    );
    await sqlite.execute(
      'CREATE TABLE "Notes" ('
      '"entryID" INTEGER NOT NULL,'
      '"note" TEXT,'
      '"color" INTEGER,'
      'PRIMARY KEY("entryID"));',
    );
    await sqlite.insert('Timestamps', {'entryID': 1, 'timestampUnixS': 50});
    await sqlite.insert('Systolic', {'entryID': 1, 'sys': Pressure.mmHg(123).kPa});
    await sqlite.insert('Diastolic', {'entryID': 1, 'dia': Pressure.mmHg(80).kPa});
    await sqlite.insert('Pulse', {'entryID': 1, 'pul': 70});
    await sqlite.insert('Timestamps', {'entryID': 2, 'timestampUnixS': 90});
    await sqlite.insert('Notes', {'entryID': 2, 'note': 'after partial migrate', 'color': null});
    await sqlite.close();

    final db = await HealthDatabase.open(directory: dir.path);
    addTearDown(db.close);

    final notes = await PowerSyncNoteRepository(db).get(DateRange.all());
    expect(notes, hasLength(1));
    expect(notes.first.note, 'after partial migrate');
    expect(File(p.join(dir.path, HealthDatabase.legacyBackupName)).existsSync(), isTrue);
  });
}
