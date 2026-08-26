import 'package:blood_pressure_app/domain/date_range.dart';
import 'package:blood_pressure_app/model/med_cache.dart';
import 'package:blood_pressure_app/model/storage/storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_providers.g.dart';

@Riverpod(keepAlive: true)
FileSettingsLoader? fileSettingsLoader(Ref ref) => null;

@Riverpod(keepAlive: true)
ExportSettings exportSettings(Ref ref) {
  throw UnimplementedError('Override exportSettingsProvider at boot');
}

@Riverpod(keepAlive: true)
CsvExportSettings csvExportSettings(Ref ref) {
  throw UnimplementedError('Override csvExportSettingsProvider at boot');
}

@Riverpod(keepAlive: true)
PdfExportSettings pdfExportSettings(Ref ref) {
  throw UnimplementedError('Override pdfExportSettingsProvider at boot');
}

@Riverpod(keepAlive: true)
ExcelExportSettings excelExportSettings(Ref ref) {
  throw UnimplementedError('Override excelExportSettingsProvider at boot');
}

@Riverpod(keepAlive: true)
IntervalStoreManager intervalStoreManager(Ref ref) {
  throw UnimplementedError('Override intervalStoreManagerProvider at boot');
}

@Riverpod(keepAlive: true)
ExportColumnsManager exportColumnsManager(Ref ref) {
  throw UnimplementedError('Override exportColumnsManagerProvider at boot');
}

@Riverpod(keepAlive: true)
MedCache medCache(Ref ref) {
  throw UnimplementedError('Override medCacheProvider at boot');
}

/// Rebuilds when the interval manager notifies.
@riverpod
DateRange currentDateRange(Ref ref, IntervalStoreManagerLocation location) {
  final manager = ref.watch(intervalStoreManagerProvider);
  void onChange() => ref.invalidateSelf();
  manager.addListener(onChange);
  ref.onDispose(() => manager.removeListener(onChange));
  return manager.get(location).currentRange;
}
