import 'package:blood_pressure_app/features/bluetooth/logic/devices/ble_weight_data.dart';
import 'package:blood_pressure_app/features/bluetooth/ui/input_card.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/model/storage/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Indication of a successful scale reading.
class WeightMeasurementSuccess extends StatelessWidget {
  /// Indicate a successful weight measurement.
  const WeightMeasurementSuccess({
    super.key,
    required this.onTap,
    required this.data,
  });

  /// Weight decoded from the scale.
  final BleWeightData data;

  /// Called when the user requests closing.
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final settings = context.watch<Settings>();
    final unit = settings.weightUnit;
    final value = unit.extract(data.asBodyweightRecord().weight);
    return GestureDetector(
      onTap: onTap,
      child: InputCard(
        onClosed: onTap,
        child: Center(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Icon(Icons.done, color: Colors.green),
              const SizedBox(height: 8),
              Text(
                localizations.measurementSuccess,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.scale),
                title: Text(localizations.weight),
                subtitle: Text('${value.toStringAsFixed(1)} ${unit.name}'),
              ),
              if (data.impedance != null && data.impedance! > 0)
                ListTile(
                  leading: const Icon(Icons.electrical_services),
                  title: Text(localizations.impedance),
                  subtitle: Text('${data.impedance!.toStringAsFixed(1)} Ω'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
