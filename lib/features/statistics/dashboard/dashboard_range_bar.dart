import 'package:blood_pressure_app/features/data_picker/interval_picker.dart';
import 'package:blood_pressure_app/model/storage/interval_store_manager.dart';
import 'package:flutter/material.dart';

/// Pill range control for a dashboard-style app bar.
class DashboardRangeBar extends StatelessWidget implements PreferredSizeWidget {
  /// Create a range bar for [type].
  const DashboardRangeBar({
    super.key,
    this.type = IntervalStoreManagerLocation.statsPage,
  });

  /// Which stored interval this control edits.
  final IntervalStoreManagerLocation type;

  @override
  Size get preferredSize => IntervalPicker.barSize;

  @override
  Widget build(BuildContext context) => IntervalPicker(type: type);
}
