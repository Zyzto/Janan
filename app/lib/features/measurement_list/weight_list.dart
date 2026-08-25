import 'package:blood_pressure_app/data_util/repository_builder.dart';
import 'package:blood_pressure_app/features/bluetooth/logic/eufy_body_composition.dart';
import 'package:blood_pressure_app/features/measurement_list/previous_measurement.dart';
import 'package:blood_pressure_app/features/measurement_list/weight_detail_screen.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/model/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:health_data_store/health_data_store.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// List of weights recorded in the contexts [BodyweightRepository].
class WeightList extends StatelessWidget {
  /// Create a list of weights
  const WeightList({super.key, required this.rangeType});

  /// The location from which the displayed interval is taken.
  final IntervalStoreManagerLocation rangeType;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat(context.select<Settings, String>((s) => s.dateFormatString));
    final weightUnit = context.select((Settings s) => s.weightUnit);
    final settings = context.watch<Settings>();
    final localizations = AppLocalizations.of(context)!;
    return RepositoryBuilder<BodyweightRecord, BodyweightRepository>(
      rangeType: rangeType,
      onData: (context, records) {
        final manager = context.watch<IntervalStoreManager>();
        final timeLimitRange = manager.get(rangeType).timeLimitRange;
        if (timeLimitRange != null) {
          records = records.where((r) {
            final time = TimeOfDay.fromDateTime(r.time);
            return time.isAfter(timeLimitRange.start) && time.isBefore(timeLimitRange.end);
          }).toList();
        }
        records.sort((a, b) => b.time.compareTo(a.time));
        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (context, idx) {
            final composition = EufyBodyComposition.fromRecord(records[idx], settings);
            final date = format.format(records[idx].time);
            return ListTile(
              title: Text(weightUnit.format(records[idx].weight)),
              subtitle: Text(composition == null
                  ? date
                  : '$date\n${localizations.bodyCompositionSubtitle(
                      composition.bodyFatPercent.toStringAsFixed(1),
                      composition.muscleKg.toStringAsFixed(1),
                    )}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => WeightDetailScreen(
                    record: records[idx],
                    previous: previousWeightInList(records, idx),
                  ),
                ));
              },
            );
          },
        );
      },
    );
  }
}
