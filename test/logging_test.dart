import 'package:blood_pressure_app/logging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initAppLogging starts Siglat in memory-only mode', () async {
    await expectLater(initAppLogging(memoryOnly: true), completes);
  });
}
