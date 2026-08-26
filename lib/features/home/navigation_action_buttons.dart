import 'package:blood_pressure_app/app.dart';
import 'package:blood_pressure_app/features/export_import/ui/export_popout.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Which shell FAB column to show.
enum NavigationActionKind {
  /// Pill check-in plus add blood pressure.
  bloodPressure,

  /// Add weight.
  weight,

  /// Open the export popout.
  export,
}

/// Floating action buttons pinned on the data tabs.
class NavigationActionButtons extends StatelessWidget {
  const NavigationActionButtons({
    super.key,
    this.kind = NavigationActionKind.bloodPressure,
  });

  /// Which buttons to show.
  final NavigationActionKind kind;

  @override
  Widget build(BuildContext context) {
    if (kind == NavigationActionKind.export) {
      return SizedBox.square(
        dimension: 56,
        child: FloatingActionButton(
          heroTag: 'floatingActionExport',
          tooltip: 'exportImport'.tr(),
          onPressed: () => showExportPopout(context),
          child: Icon(
            Icons.file_download_outlined,
            semanticLabel: 'export'.tr(),
          ),
        ),
      );
    }

    final isWeight = kind == NavigationActionKind.weight;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isWeight) ...[
          FloatingActionButton.small(
            heroTag: 'floatingActionPill',
            tooltip: 'logMedication'.tr(),
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoute.addMedicine.path,
            ),
            child: Icon(
              Symbols.pill,
              fill: 1,
              semanticLabel: 'logMedication'.tr(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox.square(
          dimension: 56,
          child: FloatingActionButton(
            heroTag: 'floatingActionAdd',
            tooltip: isWeight ? 'weight'.tr() : 'addMeasurement'.tr(),
            autofocus: true,
            onPressed: () => Navigator.of(context).pushNamed(
              isWeight ? AppRoute.addWeight.path : AppRoute.add.path,
            ),
            child: Icon(Icons.add, semanticLabel: 'addMeasurement'.tr()),
          ),
        ),
      ],
    );
  }
}
