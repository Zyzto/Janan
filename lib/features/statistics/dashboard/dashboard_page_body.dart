import 'package:flutter/material.dart';
import 'package:safaeh/safaeh.dart';

/// Padded, width-capped column used by dashboard-style pages.
class DashboardPageBody extends StatelessWidget {
  /// Create a dashboard-style scroll body.
  const DashboardPageBody({
    super.key,
    required this.children,
  });

  /// Cards stacked with dashboard spacing.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = SafaehTheme.of(context);
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) spaced.add(const SizedBox(height: 12));
      spaced.add(children[i]);
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: tokens.contentMaxWidth),
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 88),
          children: spaced,
        ),
      ),
    );
  }
}
