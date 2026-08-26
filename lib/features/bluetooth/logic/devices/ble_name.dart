/// Letters and digits from an advertised BLE name, used to compare `BM 59`
/// with `BM59` or `eufy T9147` with `T9147`.
String normalizeBleName(String value) =>
    value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

/// Whether [advertisedName] contains any of [tokens] after [normalizeBleName].
bool bleNameContainsAnyToken(String? advertisedName, Iterable<String> tokens) {
  if (advertisedName == null || advertisedName.isEmpty) return false;
  final normalized = normalizeBleName(advertisedName);
  if (normalized.isEmpty) return false;
  return tokens.any(normalized.contains);
}
