import 'package:blood_pressure_app/components/pressure_text.dart';
import 'package:blood_pressure_app/data_util/entry_context.dart';
import 'package:blood_pressure_app/features/measurement_list/metric_change.dart';
import 'package:blood_pressure_app/features/measurement_list/metric_change_chip.dart';
import 'package:blood_pressure_app/features/measurement_list/metric_info.dart';
import 'package:blood_pressure_app/features/measurement_list/metric_info_dialog.dart';
import 'package:blood_pressure_app/features/measurement_list/previous_measurement.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/model/blood_pressure/pressure_unit.dart';
import 'package:blood_pressure_app/model/combined_entry.dart';
import 'package:blood_pressure_app/model/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide ProviderNotFoundException;
import 'package:health_data_store/health_data_store.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Full blood-pressure entry with comparison to the previous reading.
class MeasurementDetailScreen extends StatefulWidget {
  /// Show [entry], optionally compared to [previous].
  const MeasurementDetailScreen({
    super.key,
    required this.entry,
    this.previous,
  });

  /// Entry to display.
  final CombinedEntry entry;

  /// Next older blood-pressure reading from the visible list, when known.
  final CombinedEntry? previous;

  @override
  State<MeasurementDetailScreen> createState() => _MeasurementDetailScreenState();
}

class _MeasurementDetailScreenState extends State<MeasurementDetailScreen> {
  BloodPressureRecord? _previousRecord;

  @override
  void initState() {
    super.initState();
    _previousRecord = widget.previous?.record;
    if (_previousRecord == null
        || (_previousRecord!.sys == null
            && _previousRecord!.dia == null
            && _previousRecord!.pul == null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadOlder());
    }
  }

  Future<void> _loadOlder() async {
    BloodPressureRepository repo;
    try {
      repo = RepositoryProvider.of<BloodPressureRepository>(context);
    } on ProviderNotFoundException {
      return;
    }
    final older = await loadOlderBloodPressure(repo, widget.entry.time);
    if (mounted) setState(() => _previousRecord = older);
  }

  Future<void> _edit() async {
    await context.createEntry(widget.entry);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final deleted = await context.deleteEntry(widget.entry);
    if (deleted && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final settings = context.watch<Settings>();
    final formatter = DateFormat(settings.dateFormatString);
    final unit = settings.preferredPressureUnit;
    final entry = widget.entry;
    final intake = entry.intake;
    return Scaffold(
      appBar: AppBar(
        title: Text(formatter.format(entry.time)),
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
          if (_hasPressureComparison)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                localizations.comparedToPrevious,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          if (entry.sys != null)
            _PressureTile(
              title: localizations.sysLong,
              kind: MetricKind.sys,
              pressure: entry.sys,
              previous: _previousRecord?.sys,
              unit: unit,
            ),
          if (entry.dia != null)
            _PressureTile(
              title: localizations.diaLong,
              kind: MetricKind.dia,
              pressure: entry.dia,
              previous: _previousRecord?.dia,
              unit: unit,
            ),
          if (entry.pul != null)
            MetricDetailTile(
              title: localizations.pulLong,
              value: '${entry.pul}',
              change: MetricChange(
                current: entry.pul!.toDouble(),
                previous: _previousRecord?.pul?.toDouble(),
              ),
              fractionDigits: 0,
              onTap: () => showMetricInfo(
                context,
                kind: MetricKind.pulse,
                current: entry.pul!.toDouble(),
                formattedValue: '${entry.pul}',
              ),
            ),
          MetricDetailTile(
            leading: const Icon(Icons.schedule),
            title: localizations.timestamp,
            value: formatter.format(entry.time),
          ),
          if (entry.note?.note?.isNotEmpty ?? false)
            ListTile(
              leading: entry.color == null
                  ? const Icon(Icons.notes)
                  : Icon(Icons.notes, color: Color(entry.color!)),
              title: Text(localizations.note),
              subtitle: Text(entry.note!.note!),
            ),
          if (intake != null)
            ListTile(
              leading: Icon(Icons.medication,
                color: intake.medicine.color == null
                    ? null
                    : Color(intake.medicine.color!)),
              title: Text(intake.medicine.designation),
              subtitle: Text('${intake.dosis.mg}mg'),
            ),
        ],
      ),
    );
  }

  bool get _hasPressureComparison =>
      _previousRecord != null
      && (_previousRecord!.sys != null
          || _previousRecord!.dia != null
          || _previousRecord!.pul != null);
}

class _PressureTile extends StatelessWidget {
  const _PressureTile({
    required this.title,
    required this.kind,
    required this.pressure,
    required this.previous,
    required this.unit,
  });

  final String title;
  final MetricKind kind;
  final Pressure? pressure;
  final Pressure? previous;
  final PressureUnit unit;

  @override
  Widget build(BuildContext context) {
    final current = _inUnit(pressure, unit);
    final formatted = current == null
        ? '—'
        : unit == PressureUnit.kPa
            ? current.toStringAsFixed(1)
            : current.round().toString();
    return ListTile(
      title: Text(title),
      subtitle: PressureText(pressure),
      onTap: current == null
          ? null
          : () => showMetricInfo(
              context,
              kind: kind,
              current: current,
              formattedValue: formatted,
            ),
      trailing: previous == null
          ? null
          : MetricChangeChip(
              change: MetricChange(
                current: current ?? 0,
                previous: _inUnit(previous, unit),
                unchangedEpsilon: unit == PressureUnit.kPa ? 0.05 : 0.5,
              ),
              fractionDigits: unit == PressureUnit.kPa ? 1 : 0,
            ),
    );
  }

  double? _inUnit(Pressure? value, PressureUnit unit) {
    if (value == null) return null;
    return switch (unit) {
      PressureUnit.mmHg => value.mmHg.toDouble(),
      PressureUnit.kPa => value.kPa,
    };
  }
}
