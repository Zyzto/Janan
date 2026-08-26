import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every locale JSON has the same keys as en.json', () {
    final dir = Directory('assets/translations');
    final en = jsonDecode(File('${dir.path}/en.json').readAsStringSync())
        as Map<String, dynamic>;
    final enKeys = en.keys.toSet();
    expect(enKeys.contains('addMeasurement'), isTrue);
    expect(enKeys.contains('searchSettings'), isTrue);
    expect(enKeys.contains('measurementSemantics'), isTrue);
    expect(enKeys.contains('onboardingSkip'), isTrue);
    expect(enKeys.contains('onboardingReplay'), isTrue);
    expect(enKeys.any((k) => k.startsWith('@')), isFalse);

    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(
        map.keys.toSet(),
        enKeys,
        reason: file.uri.pathSegments.last,
      );
      expect(map.values.every((v) => v is String && v.isNotEmpty), isTrue);
    }
  });
}
