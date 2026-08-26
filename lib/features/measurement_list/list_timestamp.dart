import 'package:blood_pressure_app/l10n/western_digits.dart';

/// Compact stamp for table rows: month name and day of month.
String formatListTimestamp(DateTime time, [String locale = 'en']) =>
    WesternDateFormat.MMMd(locale).format(time.toLocal());
