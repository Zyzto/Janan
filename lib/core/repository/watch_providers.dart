import 'package:blood_pressure_app/core/repository/repository_providers.dart';
import 'package:blood_pressure_app/core/settings/storage_providers.dart';
import 'package:blood_pressure_app/domain/domain.dart';
import 'package:blood_pressure_app/model/storage/interval_store_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_providers.g.dart';

@riverpod
Stream<List<BloodPressureRecord>> bloodPressureRecords(
  Ref ref,
  IntervalStoreManagerLocation location,
) async* {
  final repo = ref.watch(bloodPressureRepositoryProvider);
  final range = ref.watch(currentDateRangeProvider(location));
  yield await repo.get(range);
  await for (final _ in repo.subscribe()) {
    yield await repo.get(range);
  }
}

@riverpod
Stream<List<Note>> notes(
  Ref ref,
  IntervalStoreManagerLocation location,
) async* {
  final repo = ref.watch(noteRepositoryProvider);
  final range = ref.watch(currentDateRangeProvider(location));
  yield await repo.get(range);
  await for (final _ in repo.subscribe()) {
    yield await repo.get(range);
  }
}

@riverpod
Stream<List<MedicineIntake>> medicineIntakes(
  Ref ref,
  IntervalStoreManagerLocation location,
) async* {
  final repo = ref.watch(medicineIntakeRepositoryProvider);
  final range = ref.watch(currentDateRangeProvider(location));
  yield await repo.get(range);
  await for (final _ in repo.subscribe()) {
    yield await repo.get(range);
  }
}

@riverpod
Stream<List<BodyweightRecord>> bodyweightRecords(
  Ref ref,
  IntervalStoreManagerLocation location,
) async* {
  final repo = ref.watch(bodyweightRepositoryProvider);
  final range = ref.watch(currentDateRangeProvider(location));
  yield await repo.get(range);
  await for (final _ in repo.subscribe()) {
    yield await repo.get(range);
  }
}

@riverpod
Stream<List<Medicine>> medicines(Ref ref) async* {
  final repo = ref.watch(medicineRepositoryProvider);
  yield await repo.getAll();
  await for (final _ in repo.subscribe()) {
    yield await repo.getAll();
  }
}
