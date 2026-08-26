import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:safaeh/safaeh.dart';

/// Show a dialog that prompts the user to confirm a deletion.
Future<bool> showConfirmDeletionDialog(BuildContext context, [String? customDescription]) async {
  final ok = await showSafaehConfirm(
    context: context,
    title: 'confirmDelete'.tr(),
    content: customDescription ?? 'confirmDeleteDesc'.tr(),
    confirmLabel: 'btnConfirm'.tr(),
    cancelLabel: 'btnCancel'.tr(),
    isDestructive: true,
    titleBuilder: (context, style) => Text('confirmDelete'.tr(), style: style),
  );
  return ok == true;
}
