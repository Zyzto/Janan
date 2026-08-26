import 'dart:io';

import 'package:blood_pressure_app/core/database/powersync_schema.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart';

/// Opens a throwaway PowerSync file. Returns false when the native binary is missing.
Future<bool> powerSyncAvailable() async {
  try {
    final probePath = p.join(
      Directory.systemTemp.path,
      'janan_powersync_probe.db',
    );
    final probe = PowerSyncDatabase(schema: schema, path: probePath);
    await probe.initialize();
    await probe.close();
    final file = File(probePath);
    if (file.existsSync()) file.deleteSync();
    return true;
  } catch (_) {
    return false;
  }
}

Future<(PowerSyncDatabase, String)> openTempHealthDb() async {
  final dbPath = p.join(
    Directory.systemTemp.path,
    'janan_health_${DateTime.now().microsecondsSinceEpoch}.db',
  );
  final db = PowerSyncDatabase(schema: schema, path: dbPath);
  await db.initialize();
  return (db, dbPath);
}
