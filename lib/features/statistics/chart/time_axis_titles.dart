import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Left-axis numeric title.
///
/// Drops a step label that would collide with the actual min or max.
Widget valueAxisTitle({
  required double value,
  required TitleMeta meta,
  required TextStyle style,
}) {
  final step = meta.appliedInterval;
  if (step > 0) {
    final isEnd = (value - meta.max).abs() < 0.01;
    final isStart = (value - meta.min).abs() < 0.01;
    if (!isEnd && (meta.max - value).abs() < step * 0.55) {
      return const SizedBox.shrink();
    }
    if (!isStart && (value - meta.min).abs() < step * 0.55) {
      return const SizedBox.shrink();
    }
  }
  return SideTitleWidget(
    meta: meta,
    child: Text(value.round().toString(), style: style),
  );
}
