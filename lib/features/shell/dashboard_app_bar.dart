import 'package:blood_pressure_app/features/data_picker/interval_picker.dart';
import 'package:blood_pressure_app/features/home/ble_home_sync_indicator.dart';
import 'package:blood_pressure_app/features/settings/app_settings.dart';
import 'package:blood_pressure_app/features/statistics/dashboard/dashboard_range_bar.dart';
import 'package:blood_pressure_app/model/storage/interval_store_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared chrome for the blood-pressure, weight, and statistics tabs.
///
/// [page] is the live [PageController.page] so the title and BLE action
/// crossfade with the swipe. The range bar does not read [page].
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Create the pinned dashboard header for [page] (0 through last data tab).
  const DashboardAppBar({
    super.key,
    required this.page,
    this.titleKeys = _defaultTitleKeys,
  });

  /// Current shell page position in the visible data tabs.
  final double page;

  /// Localization keys for the visible data-tab titles, in swipe order.
  final List<String> titleKeys;

  static const _defaultTitleKeys = ['title', 'weight', 'statistics'];

  static const _rangeBar = DashboardRangeBar(
    type: IntervalStoreManagerLocation.mainPage,
  );

  /// Toolbar + range bar, plus the status-bar inset when [primary] is true.
  static double extentOf(BuildContext context) =>
      MediaQuery.paddingOf(context).top +
      kToolbarHeight +
      IntervalPicker.barSize.height;

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + IntervalPicker.barSize.height,
  );

  @override
  Widget build(BuildContext context) {
    final last = (titleKeys.length - 1).toDouble().clamp(0.0, double.infinity);
    final clamped = page.clamp(0.0, last);
    return AppBar(
      automaticallyImplyLeading: false,
      title: _CrossfadeTitles(page: clamped, titleKeys: titleKeys),
      actions: [
        _BleHomeAction(opacity: (1.0 - clamped).clamp(0.0, 1.0)),
      ],
      bottom: _rangeBar,
    );
  }
}

class _CrossfadeTitles extends StatelessWidget {
  const _CrossfadeTitles({
    required this.page,
    required this.titleKeys,
  });

  final double page;
  final List<String> titleKeys;

  @override
  Widget build(BuildContext context) {
    if (titleKeys.isEmpty) return const SizedBox.shrink();
    final last = titleKeys.length - 1;
    final low = page.floor().clamp(0, last);
    final high = page.ceil().clamp(0, last);
    final indices = {low, high};
    if (indices.length == 1) {
      return Text(titleKeys[low].tr());
    }
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        for (final i in indices)
          Opacity(
            opacity: (1.0 - (page - i).abs()).clamp(0.0, 1.0),
            child: Text(titleKeys[i].tr()),
          ),
      ],
    );
  }
}

class _BleHomeAction extends StatelessWidget {
  const _BleHomeAction({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();
    try {
      ProviderScope.containerOf(context, listen: false).read(appSettingsProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    return Opacity(
      opacity: opacity,
      child: const BleHomeSyncIndicator(),
    );
  }
}
