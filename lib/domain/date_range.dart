import 'package:blood_pressure_app/domain/datetime_seconds.dart';

/// Encapsulates a start and end [DateTime] that represent the range of dates.
///
/// The range includes the [start] and [end] dates. The [start] and [end] dates
/// may be equal to indicate a date range of a single day. The [start] date must
/// not be after the [end] date.
class DateRange {
  /// Creates a date range for the given start and end [DateTime].
  DateRange({
    required this.start,
    required this.end,
  }) : assert(!end.isBefore(start));

  /// Creates a date range from unix epoch through a far-future end.
  ///
  /// The end is not "today" so future-dated entries still load and delete.
  factory DateRange.all() => DateRange(
        start: DateTime.fromMillisecondsSinceEpoch(0),
        end: DateTime.utc(9999, 12, 31, 23, 59, 59),
      );

  /// The start of the range of dates.
  final DateTime start;

  /// The end of the range of dates.
  final DateTime end;

  /// Returns a [Duration] of the time between [start] and [end].
  Duration get duration => end.difference(start);

  /// Gets the [start] timestamp in seconds since epoch.
  int get startStamp => start.secondsSinceEpoch;

  /// Gets the [end] timestamp in seconds since epoch.
  int get endStamp => end.secondsSinceEpoch;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}
