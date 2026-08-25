import 'package:blood_pressure_app/app.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Floating action button to add a measurement.
class NavigationActionButtons extends StatelessWidget {
  /// Create the main add-measurement FAB.
  const NavigationActionButtons({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 75,
    child: FittedBox(
      child: FloatingActionButton(
        heroTag: 'floatingActionAdd',
        tooltip: AppLocalizations.of(context)!.addMeasurement,
        autofocus: true,
        onPressed: () => Navigator.of(context).pushNamed(AppRoute.add.path),
        child: const Icon(Icons.add),
      ),
    ),
  );
}
