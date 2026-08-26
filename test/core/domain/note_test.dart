import 'package:blood_pressure_app/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('should initialize', () {
    final time = DateTime.now();
    final note = Note(
      time: time,
      note: 'testNote',
      color: 0xFF42A5F5,
    );
    expect(note.time, equals(time));
    expect(note.color, equals(0xFF42A5F5));
    expect(note.note, equals('testNote'));
    expect(
      note,
      equals(Note(
        time: time,
        note: 'testNote',
        color: 0xFF42A5F5,
      )),
    );
  });
}
