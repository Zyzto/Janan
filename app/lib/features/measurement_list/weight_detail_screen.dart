import 'package:blood_pressure_app/components/confirm_deletion_dialog.dart';
import 'package:blood_pressure_app/data_util/entry_context.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/eufy_body_composition.dart';
import 'package:blood_pressure_app/features/measurement_list/metric_change.dart';
import 'package:blood_pressure_app/features/measurement_list/metric_change_chip.dart';
import 'package:blood_pressure_app/features/measurement_list/metric_info.dart';
import 'package:blood_pressure_app/features/measurement_list/metric_info_dialog.dart';
import 'package:blood_pressure_app/features/measurement_list/previous_measurement.dart';
import 'package:blood_pressure_app/features/settings/body_profile_screen.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/model/combined_entry.dart';
import 'package:blood_pressure_app/model/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide ProviderNotFoundException;
import 'package:health/health.dart';
import 'package:health_data_store/health_data_store.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Full weigh-in with comparison to the previous measurement.
class WeightDetailScreen extends StatefulWidget {
  /// Show [record], optionally compared to [previous].
  const WeightDetailScreen({
    super.key,
    required this.record,
    this.previous,
  });

  /// Weigh-in to display.
  final BodyweightRecord record;

  /// Next older weigh-in from the visible list, when known.
  final BodyweightRecord? previous;

  @override
  State<WeightDetailScreen> createState() => _WeightDetailScreenState();
}

class _WeightDetailScreenState extends State<WeightDetailScreen> {
  BodyweightRecord? _previous;

  @override
  void initState() {
    super.initState();
    _previous = widget.previous;
    if (_previous == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadOlder());
    }
  }

  Future<void> _loadOlder() async {
    BodyweightRepository repo;
    try {
      repo = RepositoryProvider.of<BodyweightRepository>(context);
    } on ProviderNotFoundException {
      return;
    }
    final older = await loadOlderWeight(repo, widget.record.time);
    if (mounted) setState(() => _previous = older);
  }

  Future<void> _edit() async {
    await context.createEntry(CombinedEntry(
      time: widget.record.time,
      weight: widget.record,
    ));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final settings = context.read<Settings>();
    if (settings.confirmDeletion && !await showConfirmDeletionDialog(context)) {
      return;
    }
    await context.read<BodyweightRepository>().remove(widget.record);
    final hcSettings = context.read<HealthConnectSettings>();
    if (hcSettings.useHealthConnect && hcSettings.syncWeightMeasurements) {
      await Health().delete(
        type: HealthDataType.WEIGHT,
        startTime: widget.record.time.subtract(const Duration(milliseconds: 500)),
        endTime: widget.record.time.add(const Duration(milliseconds: 500)),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final settings = context.watch<Settings>();
    final unit = settings.weightUnit;
    final formatter = DateFormat(settings.dateFormatString);
    final composition = EufyBodyComposition.fromRecord(widget.record, settings);
    final previousComposition = _previous == null
        ? null
        : EufyBodyComposition.fromRecord(_previous!, settings);
    final heightCm = settings.bodyHeightCm;
    final bmi = _bmi(widget.record.weight.kg, heightCm);
    final previousBmi = _previous == null
        ? null
        : _bmi(_previous!.weight.kg, heightCm);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.weight),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, semanticLabel: localizations.edit),
            onPressed: _edit,
          ),
          IconButton(
            icon: Icon(Icons.delete, semanticLabel: localizations.delete),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        children: [
          if (_previous != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                localizations.comparedToPrevious,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          MetricDetailTile(
            leading: const Icon(Icons.scale),
            title: localizations.weight,
            value: unit.format(widget.record.weight),
            unit: unit.name,
            change: MetricChange(
              current: unit.extract(widget.record.weight),
              previous: _previous == null ? null : unit.extract(_previous!.weight),
            ),
            onTap: () => showMetricInfo(
              context,
              kind: MetricKind.weight,
              current: unit.extract(widget.record.weight),
              formattedValue: unit.format(widget.record.weight),
              weightKg: widget.record.weight.kg,
            ),
          ),
          MetricDetailTile(
            leading: const Icon(Icons.schedule),
            title: localizations.timestamp,
            value: formatter.format(widget.record.time),
          ),
          if (bmi != null)
            MetricDetailTile(
              leading: const Icon(Icons.monitor_heart_outlined),
              title: localizations.bmi,
              value: bmi.toStringAsFixed(1),
              change: MetricChange(
                current: bmi,
                previous: previousBmi,
              ),
              onTap: () => showMetricInfo(
                context,
                kind: MetricKind.bmi,
                current: bmi,
                formattedValue: bmi.toStringAsFixed(1),
                weightKg: widget.record.weight.kg,
              ),
            ),
          if (composition != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                localizations.bodyCompositionEstimated,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            MetricDetailTile(
              leading: const Icon(Icons.pie_chart_outline),
              title: localizations.bodyFat,
              value: '${composition.bodyFatPercent.toStringAsFixed(1)} %',
              unit: '%',
              change: MetricChange(
                current: composition.bodyFatPercent,
                previous: previousComposition?.bodyFatPercent,
              ),
              onTap: () => showMetricInfo(
                context,
                kind: MetricKind.bodyFat,
                current: composition.bodyFatPercent,
                formattedValue: '${composition.bodyFatPercent.toStringAsFixed(1)} %',
                weightKg: widget.record.weight.kg,
              ),
            ),
            MetricDetailTile(
              leading: const Icon(Icons.fitness_center),
              title: localizations.muscleMass,
              value: '${composition.muscleKg.toStringAsFixed(1)} kg',
              unit: 'kg',
              change: MetricChange(
                current: composition.muscleKg,
                previous: previousComposition?.muscleKg,
                polarity: MetricPolarity.higherIsBetter,
              ),
              onTap: () => showMetricInfo(
                context,
                kind: MetricKind.muscle,
                current: composition.muscleKg,
                formattedValue: '${composition.muscleKg.toStringAsFixed(1)} kg',
                weightKg: widget.record.weight.kg,
              ),
            ),
            MetricDetailTile(
              leading: const Icon(Icons.accessibility),
              title: localizations.boneMass,
              value: '${composition.boneKg.toStringAsFixed(1)} kg',
              unit: 'kg',
              change: MetricChange(
                current: composition.boneKg,
                previous: previousComposition?.boneKg,
                polarity: MetricPolarity.higherIsBetter,
              ),
              onTap: () => showMetricInfo(
                context,
                kind: MetricKind.bone,
                current: composition.boneKg,
                formattedValue: '${composition.boneKg.toStringAsFixed(1)} kg',
                weightKg: widget.record.weight.kg,
              ),
            ),
            MetricDetailTile(
              leading: const Icon(Icons.water_drop_outlined),
              title: localizations.bodyWater,
              value: '${composition.waterPercent.toStringAsFixed(1)} %',
              unit: '%',
              change: MetricChange(
                current: composition.waterPercent,
                previous: previousComposition?.waterPercent,
                polarity: MetricPolarity.higherIsBetter,
              ),
              onTap: () => showMetricInfo(
                context,
                kind: MetricKind.water,
                current: composition.waterPercent,
                formattedValue: '${composition.waterPercent.toStringAsFixed(1)} %',
                weightKg: widget.record.weight.kg,
              ),
            ),
            MetricDetailTile(
              leading: const Icon(Icons.monitor_weight_outlined),
              title: localizations.leanBodyMass,
              value: '${composition.lbmKg.toStringAsFixed(1)} kg',
              unit: 'kg',
              change: MetricChange(
                current: composition.lbmKg,
                previous: previousComposition?.lbmKg,
                polarity: MetricPolarity.higherIsBetter,
              ),
              onTap: () => showMetricInfo(
                context,
                kind: MetricKind.lbm,
                current: composition.lbmKg,
                formattedValue: '${composition.lbmKg.toStringAsFixed(1)} kg',
                weightKg: widget.record.weight.kg,
              ),
            ),
            MetricDetailTile(
              leading: const Icon(Icons.local_fire_department_outlined),
              title: localizations.bmr,
              value: '${composition.bmrKcal} kcal',
              unit: 'kcal',
              fractionDigits: 0,
              change: MetricChange(
                current: composition.bmrKcal.toDouble(),
                previous: previousComposition?.bmrKcal.toDouble(),
                polarity: MetricPolarity.neutral,
              ),
              onTap: () => showMetricInfo(
                context,
                kind: MetricKind.bmr,
                current: composition.bmrKcal.toDouble(),
                formattedValue: '${composition.bmrKcal} kcal',
                weightKg: widget.record.weight.kg,
              ),
            ),
          ] else if (widget.record.impedanceOhm != null && !settings.hasBodyProfile)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(localizations.bodyProfileIncomplete),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute<void>(
                  builder: (context) => const BodyProfileScreen(),
                ));
              },
            ),
        ],
      ),
    );
  }

  double? _bmi(double weightKg, double? heightCm) {
    if (heightCm == null || heightCm <= 0) return null;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }
}
