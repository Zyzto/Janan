import 'dart:async';

import 'package:blood_pressure_app/core/repository/powersync_medicine_repository.dart';
import 'package:blood_pressure_app/domain/domain.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

/// PowerSync implementation of [MedicineIntakeRepository].
class PowerSyncMedicineIntakeRepository extends MedicineIntakeRepository {
  PowerSyncMedicineIntakeRepository(this._db);

  final PowerSyncDatabase _db;
  final _uuid = const Uuid();
  final _controller = StreamController<MedicineIntake?>.broadcast();

  @override
  Future<void> add(MedicineIntake intake) async {
    final medRepo = PowerSyncMedicineRepository(_db);
    final medId = await medRepo.idFor(intake.medicine, includeRemoved: true);
    assert(medId != null, 'Intakes require a medicine that has been added');
    if (medId == null) return;

    final timeSec = intake.time.secondsSinceEpoch;
    final existing = await _db.getAll(
      'SELECT id FROM intakes WHERE timestamp_unix_s = ?',
      [timeSec],
    );
    if (existing.isEmpty) {
      await _db.execute(
        'INSERT INTO intakes (id, timestamp_unix_s, med_id, dosis_mg) '
        'VALUES (?, ?, ?, ?)',
        [_uuid.v4(), timeSec, medId, intake.dosis.mg],
      );
    } else {
      await _db.execute(
        'UPDATE intakes SET med_id = ?, dosis_mg = ? WHERE id = ?',
        [medId, intake.dosis.mg, existing.first['id']],
      );
    }
    _controller.add(intake);
  }

  @override
  Future<List<MedicineIntake>> get(DateRange range) async {
    final results = await _db.getAll(
      'SELECT i.timestamp_unix_s, i.dosis_mg, m.designation, m.color, '
      'm.default_dose_mg, m.dose_unit '
      'FROM intakes AS i '
      'JOIN medicines AS m ON m.id = i.med_id '
      'WHERE i.timestamp_unix_s BETWEEN ? AND ? AND i.dosis_mg IS NOT NULL',
      [range.startStamp, range.endStamp],
    );
    return [
      for (final r in results)
        MedicineIntake(
          time: DateTimeS.fromSecondsSinceEpoch(r['timestamp_unix_s'] as int),
          dosis: Weight.mg((r['dosis_mg'] as num).toDouble()),
          medicine: Medicine(
            designation: r['designation'] as String,
            dosis: _decodeMg(r['default_dose_mg']),
            unit: MedicationUnit.parse(r['dose_unit']),
            color: r['color'] as int?,
          ),
        ),
    ];
  }

  @override
  Future<void> remove(MedicineIntake intake) async {
    await _db.execute(
      'DELETE FROM intakes WHERE timestamp_unix_s = ? AND dosis_mg = ?',
      [intake.time.secondsSinceEpoch, intake.dosis.mg],
    );
    _controller.add(null);
  }

  @override
  Stream<MedicineIntake?> subscribe() => _controller.stream;

  Weight? _decodeMg(Object? value) {
    if (value is! num) return null;
    return Weight.mg(value.toDouble());
  }
}
