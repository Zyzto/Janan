import 'package:blood_pressure_app/core/repository/repo_context.dart';
import 'package:blood_pressure_app/model/storage/types/export_format_setting.dart';
import 'package:flutter/widgets.dart';

/// Active column preset for the current export format.
String? readActivePresetId(BuildContext context) {
  final format = context.exportSettings.exportFormat;
  return switch (format) {
    ExportFormat.csv => context.csvExportSettings.activePreset,
    ExportFormat.pdf => context.pdfExportSettings.activePreset,
    ExportFormat.xls => context.excelExportSettings.activePreset,
    ExportFormat.db => null,
  };
}

/// Store [presetId] as the active column preset for the current export format.
void writeActivePresetId(BuildContext context, String presetId) {
  switch (context.exportSettings.exportFormat) {
    case ExportFormat.csv:
      context.csvExportSettings.activePreset = presetId;
    case ExportFormat.pdf:
      context.pdfExportSettings.activePreset = presetId;
    case ExportFormat.xls:
      context.excelExportSettings.activePreset = presetId;
    case ExportFormat.db:
      break;
  }
}
