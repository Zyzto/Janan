import 'package:blood_pressure_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Compact placeholder shown while connecting to a meter and reading.
class DeviceConnectingPlaceholder extends StatelessWidget {
  /// Create a connecting placeholder.
  const DeviceConnectingPlaceholder({
    super.key,
    this.deviceName,
    this.onClosed,
  });

  /// Advertised name of the meter, when known.
  final String? deviceName;

  /// Called when the user dismisses the connection.
  final VoidCallback? onClosed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final title = deviceName == null || deviceName!.trim().isEmpty
        ? localizations.connectingToMeter
        : localizations.connectingToDevice(deviceName!);
    return Card(
      color: theme.colorScheme.primaryContainer,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(title),
        subtitle: Text(localizations.readingMeasurement),
        trailing: onClosed == null
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                tooltip: localizations.btnCancel,
                onPressed: onClosed,
              ),
      ),
    );
  }
}
