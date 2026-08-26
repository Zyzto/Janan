import 'dart:async';

import 'package:blood_pressure_app/domain/domain.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

/// PowerSync implementation of [NoteRepository].
class PowerSyncNoteRepository extends NoteRepository {
  PowerSyncNoteRepository(this._db);

  final PowerSyncDatabase _db;
  final _uuid = const Uuid();
  final _controller = StreamController<Note?>.broadcast();

  @override
  Future<void> add(Note note) async {
    if (note.note == null && note.color == null) {
      assert(false, 'Attempting to store a note without content and color');
      return;
    }
    final timeSec = note.time.secondsSinceEpoch;
    final existing = await _db.getAll(
      'SELECT id FROM notes WHERE timestamp_unix_s = ?',
      [timeSec],
    );
    if (existing.isEmpty) {
      await _db.execute(
        'INSERT INTO notes (id, timestamp_unix_s, note, color) VALUES (?, ?, ?, ?)',
        [_uuid.v4(), timeSec, note.note, note.color],
      );
    } else {
      await _db.execute(
        'UPDATE notes SET note = ?, color = ? WHERE id = ?',
        [note.note, note.color, existing.first['id']],
      );
    }
    _controller.add(note);
  }

  @override
  Future<List<Note>> get(DateRange range) async {
    final result = await _db.getAll(
      'SELECT timestamp_unix_s, note, color FROM notes '
      'WHERE timestamp_unix_s BETWEEN ? AND ? '
      'AND (note IS NOT NULL OR color IS NOT NULL)',
      [range.startStamp, range.endStamp],
    );
    return [
      for (final row in result)
        Note(
          time: DateTimeS.fromSecondsSinceEpoch(row['timestamp_unix_s'] as int),
          note: row['note'] as String?,
          color: _decodeInt(row['color']),
        ),
    ];
  }

  @override
  Future<void> remove(Note value) async {
    await _db.execute(
      'DELETE FROM notes WHERE timestamp_unix_s = ?',
      [value.time.secondsSinceEpoch],
    );
    _controller.add(null);
  }

  @override
  Stream<Note?> subscribe() => _controller.stream;

  int? _decodeInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}
