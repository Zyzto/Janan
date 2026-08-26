import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Settings object that can be serialized and reset.
abstract class PersistableSettings extends ChangeNotifier {
  /// Serialize to a restoreable map.
  Map<String, dynamic> toMap();

  /// Serialize to a restoreable string.
  String toJson() => jsonEncode(toMap());

  /// Reset all fields to their default values.
  void reset();
}

/// Decode a settings JSON object, or `null` if it is not a map.
Map<String, dynamic>? decodeSettingsMap(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } catch (e) {
    assert(e is FormatException || e is TypeError);
  }
  return null;
}
