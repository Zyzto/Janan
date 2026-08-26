import 'package:blood_pressure_app/theme/app_text.dart';
import 'package:flutter/material.dart';
import 'package:safaeh/safaeh.dart';

/// Titled surface used by dashboard cards.
class DashboardSection extends StatelessWidget {
  /// Create a rounded dashboard card.
  const DashboardSection({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.padding,
    this.accentColor,
  });

  /// Card heading.
  final String? title;

  /// Optional line under [title].
  final String? subtitle;

  /// Optional leading icon for [title].
  final IconData? icon;

  /// Optional control aligned with [title].
  final Widget? trailing;

  /// Card body.
  final Widget child;

  /// When set, the card is tappable.
  final VoidCallback? onTap;

  /// Inner padding. Defaults to 16.
  final EdgeInsetsGeometry? padding;

  /// Optional start-edge accent strip.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = SafaehTheme.of(context);
    final inset = padding ?? const EdgeInsetsDirectional.all(20);
    final hasHeader = title != null || subtitle != null || trailing != null || icon != null;
    final header = !hasHeader
        ? null
        : Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
              ],
              if (title != null || subtitle != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: AppText.title(context),
                        ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: AppText.subtitle(context),
                        ),
                    ],
                  ),
                )
              else
                const Spacer(),
              ?trailing,
            ],
          );

    Widget body = Padding(
      padding: inset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            header,
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );

    if (accentColor != null) {
      body = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: accentColor!,
              child: const SizedBox(width: 4),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radius),
      ),
      child: onTap == null
          ? body
          : InkWell(onTap: onTap, child: body),
    );
  }
}
