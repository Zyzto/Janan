import 'package:blood_pressure_app/data_util/entry_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:blood_pressure_app/domain/domain.dart';

import '../model/export_import/record_formatter_test.dart';
import '../util.dart';

void main() {
  testWidgets('fully deletes entries', (tester) async {
    final entry = mockEntry(time: DateTime.now(), sys: 123, note: 'test', intake: (mockMedicine(), 42.0));

    final BloodPressureRepository bpRepo = MockBloodPressureRepository() as BloodPressureRepository;
    final NoteRepository noteRepo = MockNoteRepository() as NoteRepository;
    final MedicineIntakeRepository intakeRepo = MockMedicineIntakeRepository() as MedicineIntakeRepository;
    await bpRepo.add(entry.record!);
    await noteRepo.add(entry.note!);
    await intakeRepo.add(entry.intake!);

    await tester.pumpWidget(await appBase(
      settings: TestSettingsSeed(confirmDeletion: false),
      bpRepo: bpRepo,
      noteRepo: noteRepo,
      intakeRepo: intakeRepo,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => context.deleteEntry(entry),
          child: Text('X'),
        ),
      ),
    ));

    expect(await bpRepo.get(DateRange.all()), hasLength(1));
    expect(await noteRepo.get(DateRange.all()), hasLength(1));
    expect(await intakeRepo.get(DateRange.all()), hasLength(1));

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    expect(await bpRepo.get(DateRange.all()), isEmpty);
    expect(await noteRepo.get(DateRange.all()), isEmpty);
    expect(await intakeRepo.get(DateRange.all()), isEmpty);
  });

  testWidgets('Also removes entries from health connect', (tester) async {
    final entry = mockEntry(time: DateTime.now(), sys: 123, dia: 456);

    final BloodPressureRepository bpRepo =
        MockBloodPressureRepository() as BloodPressureRepository;
    final NoteRepository noteRepo = MockNoteRepository() as NoteRepository;
    final MedicineIntakeRepository intakeRepo =
        MockMedicineIntakeRepository() as MedicineIntakeRepository;
    final fakeHealth = _FakeHealth();
    await bpRepo.add(entry.record!);

    await tester.pumpWidget(await appBase(
      settings: TestSettingsSeed(
        confirmDeletion: false,
        useHealthConnect: true,
        syncPressureMeasurements: true,
      ),
      bpRepo: bpRepo,
      noteRepo: noteRepo,
      intakeRepo: intakeRepo,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => context.deleteEntry(entry, fakeHealth),
          child: Text('X'),
        ),
      ),
    ));

    expect(fakeHealth.deletionRequests, isEmpty);

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    expect(fakeHealth.deletionRequests,
        contains(HealthDataType.BLOOD_PRESSURE_SYSTOLIC));
    expect(fakeHealth.deletionRequests,
        contains(HealthDataType.BLOOD_PRESSURE_DIASTOLIC));
    expect(fakeHealth.deletionRequests, hasLength(2));
  });
}

class _FakeHealth extends Fake implements Health {
  _FakeHealth();

  List<HealthDataType> deletionRequests = [];

  @override
  Future<bool> delete(
      {required HealthDataType type,
      required DateTime startTime,
      DateTime? endTime}) async {
    deletionRequests.add(type);
    return true;
  }
}
