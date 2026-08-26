import 'package:flutter/painting.dart';
import 'package:intl/intl.dart' show Bidi;

/// Unicode FSI / PDI — display-only, never persist.
String isolateBidi(String text) => '\u2068$text\u2069';

String unwrapBidiIsolates(String text) =>
    text.replaceAll('\u2068', '').replaceAll('\u2069', '');

/// Keep readings and SI units LTR inside RTL copy.
String isolateLtr(String text) => '\u2068$text\u2069';

TextDirection? resolveUserTextDirection(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  if (!_hasStrongDirectional(trimmed)) return null;
  return Bidi.detectRtlDirectionality(trimmed)
      ? TextDirection.rtl
      : TextDirection.ltr;
}

bool _hasStrongDirectional(String text) {
  for (final unit in text.runes) {
    if (unit >= 0x0590 && unit <= 0x08FF) return true;
    if (unit >= 0xFB1D && unit <= 0xFDFF) return true;
    if (unit >= 0xFE70 && unit <= 0xFEFF) return true;
    if (unit >= 0x0041 && unit <= 0x005A) return true;
    if (unit >= 0x0061 && unit <= 0x007A) return true;
    if (unit >= 0x00C0 && unit <= 0x024F) return true;
    if (unit >= 0x0400 && unit <= 0x04FF) return true;
    if (unit >= 0x3040 && unit <= 0x30FF) return true;
    if (unit >= 0x4E00 && unit <= 0x9FFF) return true;
    if (unit >= 0xAC00 && unit <= 0xD7AF) return true;
  }
  return false;
}
