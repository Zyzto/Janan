import 'package:blood_pressure_app/core/repository/repo_context.dart';
import 'package:blood_pressure_app/domain/domain.dart';
import 'package:blood_pressure_app/features/statistics/dashboard/dashboard_snapshot.dart';
import 'package:blood_pressure_app/logging.dart';
import 'package:blood_pressure_app/model/combined_entry.dart';
import 'package:blood_pressure_app/model/storage/interval_store_manager.dart';
import 'package:blood_pressure_app/model/storage/types/time_range.dart';
import 'package:flutter/widgets.dart';

/// Load the records that should be exported (oldest first).
Future<List<CombinedEntry>> loadExportEntries(
  BuildContext context, {
  IntervalStoreManagerLocation rangeLocation =
      IntervalStoreManagerLocation.exportPage,
}) async {
  final interval = context.intervalStoreManager.get(rangeLocation);
  final bpRepo = context.bpRepo;
  final noteRepo = context.noteRepo;
  final intakeRepo = context.intakeRepo;
  final weightRepo = context.weightRepo;
  Log.debug('loadExportEntries - location=$rangeLocation range=${interval.currentRange}');
  return assembleExportEntries(
    records: await bpRepo.get(interval.currentRange),
    notes: await noteRepo.get(interval.currentRange),
    intakes: await intakeRepo.get(interval.currentRange),
    weights: await weightRepo.get(interval.currentRange),
    timeLimitRange: interval.timeLimitRange,
  );
}

/// Merge and filter already-fetched records for export (oldest first).
List<CombinedEntry> assembleExportEntries({
  required List<BloodPressureRecord> records,
  required List<Note> notes,
  required List<MedicineIntake> intakes,
  required List<BodyweightRecord> weights,
  TimeRange? timeLimitRange,
}) {
  final filteredRecords = recordsInTimeLimit(records, timeLimitRange);
  final filteredNotes = notes
      .where((note) => isInTimeLimit(note.time, timeLimitRange))
      .toList();
  final filteredIntakes = intakes
      .where((intake) => isInTimeLimit(intake.time, timeLimitRange))
      .toList();
  final filteredWeights = weights
      .where((weight) => isInTimeLimit(weight.time, timeLimitRange))
      .toList();

  final entries = CombinedEntryList.merged(
    filteredRecords,
    filteredNotes,
    filteredIntakes,
    filteredWeights,
  );
  entries.sort((a, b) => a.time.compareTo(b.time));
  Log.debug('assembleExportEntries - merged to ${entries.length} entries');
  return entries;
}
