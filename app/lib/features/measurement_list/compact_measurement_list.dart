import 'package:blood_pressure_app/components/nullable_text.dart';
import 'package:blood_pressure_app/components/pressure_text.dart';
import 'package:blood_pressure_app/features/measurement_list/measurement_detail_screen.dart';
import 'package:blood_pressure_app/features/measurement_list/previous_measurement.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:blood_pressure_app/model/combined_entry.dart';
import 'package:blood_pressure_app/model/storage/settings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// A more compact [BloodPressureRecord] list that is less verbose.
class CompactMeasurementList extends StatefulWidget {
  /// Create a more compact, less verbose measurement list.
  const CompactMeasurementList({super.key,
    required this.data,
  });

  /// Entries sorted with newest ordered first.
  final List<CombinedEntry> data;

  @override
  State<CompactMeasurementList> createState() => _CompactMeasurementListState();
}

class _CompactMeasurementListState extends State<CompactMeasurementList> {
  List<int> _tableElementsSizes = [33, 9, 9, 9, 30];
  int _sideFlex = 1;
  late DateFormat formatter;

  @override
  void initState() {
    super.initState();
    formatter = DateFormat('yyyy-MM-dd HH:mm');
  }

  Widget _buildHeader() => Row(
    children: [
      Expanded(
        flex: _sideFlex,
        child: const SizedBox(),
      ),
      Expanded(
        flex: _tableElementsSizes[0],
        child: Text(AppLocalizations.of(context)!.time, style: const TextStyle(fontWeight: FontWeight.bold)),),
      Expanded(
        flex: _tableElementsSizes[1],
        child: Text(AppLocalizations.of(context)!.sysShort,
          style: TextStyle(fontWeight: FontWeight.bold, color: context.select<Settings, Color>((s) => s.sysColor))),),
      Expanded(
        flex: _tableElementsSizes[2],
        child: Text(AppLocalizations.of(context)!.diaShort,
          style: TextStyle(fontWeight: FontWeight.bold, color: context.select<Settings, Color>((s) => s.diaColor))),),
      Expanded(
        flex: _tableElementsSizes[3],
        child: Text(AppLocalizations.of(context)!.pulShort,
          style: TextStyle(fontWeight: FontWeight.bold, color: context.select<Settings, Color>((s) => s.pulColor))),),
      Expanded(
        flex: _tableElementsSizes[4],
        child: Text(AppLocalizations.of(context)!.notes, style: const TextStyle(fontWeight: FontWeight.bold)),),
      Expanded(
        flex: _sideFlex,
        child: const SizedBox(),
      ),
    ],
  );

  Widget _itemBuilder(BuildContext context, int index) {
    final entry = widget.data[index];
    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => MeasurementDetailScreen(
                entry: entry,
                previous: previousBloodPressureInList(widget.data, index),
              ),
            ));
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            child: Row(children: [
              Expanded(
                flex: _sideFlex,
                child: const SizedBox(),
              ),
              Expanded(
                flex: _tableElementsSizes[0],
                child: Text(formatter.format(entry.time)),),
              Expanded(
                  flex: _tableElementsSizes[1],
                  child: PressureText(entry.sys)),
              Expanded(
                flex: _tableElementsSizes[2],
                child: PressureText(entry.dia),),
              Expanded(
                flex: _tableElementsSizes[3],
                child: NullableText(entry.pul?.toString()),),
              Expanded(
                flex: _tableElementsSizes[4],
                child: NullableText(() {
                  String note = entry.note?.note ?? '';
                  final i = entry.intake;
                  if (i != null) {
                    note += '${i.medicine.designation}(${i.dosis.mg}mg)';
                  }
                  return note.isEmpty ? null : note;
                }()),
              ),
              Expanded(
                flex: _sideFlex,
                child: const SizedBox(),
              ),
            ],),
          ),
        ),
        const Divider(
          thickness: 1,
          height: 1,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    formatter = DateFormat(context.select<Settings, String>((s) => s.dateFormatString));
    if (MediaQuery.of(context).size.width < 1000) {
      _tableElementsSizes = [33, 9, 9, 9, 30];
      _sideFlex = 1;
    } else {
      _tableElementsSizes = [20, 5, 5, 5, 60];
      _sideFlex = 5;
    }
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(
          height: 10,
        ),
        Divider(
          height: 0,
          thickness: 2,
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        Expanded(
          child: Builder(
            builder: (BuildContext context) {
              if (widget.data.isEmpty) return Text(AppLocalizations.of(context)!.errNoData);
              return ListView.builder(
                itemCount: widget.data.length,
                shrinkWrap: true,
                padding: const EdgeInsets.all(2),
                itemBuilder: _itemBuilder,
              );
            },
          ),
        ),
      ],
    );
  }
}
