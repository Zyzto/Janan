import 'package:blood_pressure_app/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('should initialize', () {
    final timeA = DateTime.now();
    final timeB = timeA.add(const Duration(hours: 20));
    final range = DateRange(start: timeA, end: timeB);
    expect(range.start, equals(timeA));
    expect(range.end, equals(timeB));
  });

  test('should throw assertion error when used incorrectly', () {
    final start = DateTime.now();
    final end = start.subtract(const Duration(hours: 20));
    expect(end.isBefore(start), true);
    expect(
      () => DateRange(start: start, end: end),
      throwsA(isA<AssertionError>()),
    );
  });

  test('should calculate difference', () {
    final timeA = DateTime.now();
    final timeB = timeA.add(const Duration(hours: 21, seconds: 42));
    final range = DateRange(start: timeA, end: timeB);
    expect(range.duration, equals(const Duration(hours: 21, seconds: 42)));
  });

  test('should determine start and end time in seconds since epoch', () {
    final timeA = DateTime.fromMillisecondsSinceEpoch(0);
    final timeB = timeA.add(const Duration(seconds: 283497));
    final range = DateRange(start: timeA, end: timeB);
    expect(range.startStamp, 0);
    expect(range.endStamp, 283497);
  });

  test('creates all range from epoch through far future', () {
    final future = DateTime.now().add(const Duration(days: 400));
    final range = DateRange.all();
    expect(range.startStamp, 0);
    expect(range.endStamp, greaterThan(future.secondsSinceEpoch));
  });
}
