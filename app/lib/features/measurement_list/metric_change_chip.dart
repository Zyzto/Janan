import 'package:blood_pressure_app/features/measurement_list/metric_change.dart';
import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Arrow and delta for a metric versus the previous measurement.
class MetricChangeChip extends StatelessWidget {
  /// Create a compact change indicator.
  const MetricChangeChip({
    super.key,
    required this.change,
    this.unit = '',
    this.fractionDigits = 1,
  });

  /// Computed difference to render.
  final MetricChange change;

  /// Unit shown after the delta, when the value changed.
  final String unit;

  /// Decimal places for the absolute delta.
  final int fractionDigits;

  @override
  Widget build(BuildContext context) {
    if (!change.hasComparison) return const SizedBox.shrink();
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = switch (change.tone) {
      MetricChangeTone.better => Colors.green,
      MetricChangeTone.worse => Colors.red,
      MetricChangeTone.neutral => theme.colorScheme.onSurface,
    };
    if (change.isUnchanged) {
      return Text(
        '—',
        style: theme.textTheme.bodySmall?.copyWith(color: color),
        semanticsLabel: localizations.noChange,
      );
    }
    final icon = change.increased ? Icons.arrow_upward : Icons.arrow_downward;
    final delta = change.formatAbsDelta(fractionDigits);
    final label = unit.isEmpty ? delta : '$delta $unit';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// List row with an optional [MetricChangeChip] as the trailing widget.
class MetricDetailTile extends StatelessWidget {
  /// Create a details row for one metric.
  const MetricDetailTile({
    super.key,
    required this.title,
    required this.value,
    this.leading,
    this.change,
    this.unit = '',
    this.fractionDigits = 1,
    this.onTap,
  });

  /// Metric name.
  final String title;

  /// Formatted current value.
  final String value;

  /// Optional leading icon.
  final Widget? leading;

  /// Comparison to the previous measurement.
  final MetricChange? change;

  /// Unit for the change chip.
  final String unit;

  /// Decimal places for the change chip.
  final int fractionDigits;

  /// Opens the metric description card.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: leading,
    title: Text(title),
    subtitle: Text(value),
    onTap: onTap,
    trailing: change == null || !change!.hasComparison
        ? null
        : MetricChangeChip(
            change: change!,
            unit: unit,
            fractionDigits: fractionDigits,
          ),
  );
}
