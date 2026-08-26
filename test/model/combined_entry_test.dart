import 'package:blood_pressure_app/domain/domain.dart';
import 'package:blood_pressure_app/model/combined_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';
import 'export_import/record_formatter_test.dart';

void main() {
  test('attaches same-day medicine-only rows to the last blood-pressure reading', () {
    final morning = mockEntry(
      time: DateTime(2026, 8, 26, 8),
      sys: 120,
      dia: 80,
    );
    final evening = mockEntry(
      time: DateTime(2026, 8, 26, 20),
      sys: 130,
      dia: 85,
    );
    final med = CombinedEntry(
      time: DateTime(2026, 8, 26, 21, 30),
      intake: mockIntake(
        mockMedicine(designation: 'amlodipine'),
        time: DateTime(2026, 8, 26, 21, 30).millisecondsSinceEpoch,
        dosis: 5,
      ),
    );

    final previousDay = CombinedEntry(
      time: DateTime(2026, 8, 25, 9),
      record: BloodPressureRecord(
        time: DateTime(2026, 8, 25, 9),
        sys: Pressure.mmHg(118),
      ),
    );
    final folded = CombinedEntryList.forBloodPressureList([
      med,
      evening,
      morning,
      previousDay,
    ]);

    expect(folded, hasLength(3));
    expect(folded.first.record?.sys?.mmHg, 130);
    expect(folded.first.dayIntakes, hasLength(1));
    expect(folded.first.dayIntakes.first.medicine.designation, 'amlodipine');
    expect(folded.first.allIntakes, hasLength(1));
    expect(folded.any((e) => e.isMedicineOnly), isFalse);
  });

  test('attaches two standalone medicines to the last reading', () {
    final reading = mockEntry(
      time: DateTime(2026, 8, 26, 8),
      sys: 120,
      dia: 80,
    );
    final first = CombinedEntry(
      time: DateTime(2026, 8, 26, 9),
      intake: mockIntake(
        mockMedicine(designation: 'amlodipine'),
        time: DateTime(2026, 8, 26, 9).millisecondsSinceEpoch,
        dosis: 5,
      ),
    );
    final second = CombinedEntry(
      time: DateTime(2026, 8, 26, 21, 30),
      intake: mockIntake(
        mockMedicine(designation: 'lisinopril'),
        time: DateTime(2026, 8, 26, 21, 30).millisecondsSinceEpoch,
        dosis: 10,
      ),
    );

    final folded = CombinedEntryList.forBloodPressureList([
      second,
      first,
      reading,
    ]);

    expect(folded, hasLength(1));
    expect(folded.first.record?.sys?.mmHg, 120);
    expect(folded.first.dayIntakes, hasLength(2));
    expect(
      folded.first.allIntakes.map((i) => i.medicine.designation),
      ['amlodipine', 'lisinopril'],
    );
  });

  test('keeps a same-time intake and attaches a standalone dose', () {
    final readingTime = DateTime(2026, 8, 26, 8);
    final withMed = CombinedEntry(
      time: readingTime,
      record: BloodPressureRecord(
        time: readingTime,
        sys: Pressure.mmHg(120),
        dia: Pressure.mmHg(80),
      ),
      intake: mockIntake(
        mockMedicine(designation: 'amlodipine'),
        time: readingTime.millisecondsSinceEpoch,
        dosis: 5,
      ),
    );
    final standalone = CombinedEntry(
      time: DateTime(2026, 8, 26, 21, 30),
      intake: mockIntake(
        mockMedicine(designation: 'lisinopril'),
        time: DateTime(2026, 8, 26, 21, 30).millisecondsSinceEpoch,
        dosis: 10,
      ),
    );

    final folded = CombinedEntryList.forBloodPressureList([
      standalone,
      withMed,
    ]);

    expect(folded, hasLength(1));
    expect(folded.first.intake?.medicine.designation, 'amlodipine');
    expect(folded.first.dayIntakes, hasLength(1));
    expect(folded.first.dayIntakes.first.medicine.designation, 'lisinopril');
    expect(folded.first.allIntakes, hasLength(2));
  });

  test('keeps a medicine-only row when there is no reading that day', () {
    final med = CombinedEntry(
      time: DateTime(2026, 8, 26, 21),
      intake: mockIntake(
        mockMedicine(designation: 'pill'),
        time: DateTime(2026, 8, 26, 21).millisecondsSinceEpoch,
      ),
    );
    final otherDay = mockEntry(
      time: DateTime(2026, 8, 25, 8),
      sys: 120,
    );

    final folded = CombinedEntryList.forBloodPressureList([med, otherDay]);
    expect(folded, hasLength(2));
    expect(folded.first.isMedicineOnly, isTrue);
  });
}
