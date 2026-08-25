import 'package:blood_pressure_app/components/nullable_text.dart';
import 'package:blood_pressure_app/components/pressure_text.dart';
import 'package:blood_pressure_app/features/measurement_list/measurement_detail_screen.dart';
import 'package:blood_pressure_app/model/combined_entry.dart';
import 'package:flutter/material.dart';

/// Display of a blood pressure measurement data.
class MeasurementListRow extends StatelessWidget {
  /// Create a display of a measurements.
  const MeasurementListRow({
    super.key,
    required this.data,
    this.previous,
  });

  /// The measurement to display.
  final CombinedEntry data;

  /// Next older blood-pressure reading, when one is in the visible list.
  final CombinedEntry? previous;

  @override
  Widget build(BuildContext context) => Material(
    color: data.note?.color == null ? null : Color(data.color!).withAlpha(30),
    child: InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => MeasurementDetailScreen(
            entry: data,
            previous: previous,
          ),
        ));
      },
      child: Container(
        decoration: data.color == null ? null : BoxDecoration(
          border: Border(
            left: BorderSide(color: Color(data.color!), width: 8),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 30,
              child: PressureText(data.sys),
            ),
            Expanded(
              flex: 30,
              child: PressureText(data.dia),
            ),
            Expanded(
              flex: 30,
              child: NullableText(data.pul?.toString()),
            ),
            Expanded(
              flex: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (data.intake != null) const Icon(Icons.medication),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
