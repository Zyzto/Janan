import 'package:blood_pressure_app/model/storage/convert_util.dart';
import 'package:flutter/foundation.dart';

/// A bluetooth device the user previously accepted.
@immutable
class KnownBleDevice {
  /// Create a remembered bluetooth device.
  const KnownBleDevice({
    required this.id,
    required this.name,
    this.autoSync = true,
  });

  /// Restore a device from [toJson].
  factory KnownBleDevice.fromJson(Map<String, dynamic> json) => KnownBleDevice(
    id: ConvertUtil.parseString(json['id']) ?? '',
    name: ConvertUtil.parseString(json['name']) ?? '',
    autoSync: ConvertUtil.parseBool(json['autoSync']) ?? true,
  );

  /// Stable identifier used to auto-connect (peripheral UUID).
  final String id;

  /// Advertised name shown in the UI.
  ///
  /// Legacy entries may store the old advertised name in [id] as well.
  final String name;

  /// Whether launch-time auto-sync should contact this device.
  final bool autoSync;

  /// Name to show to the user.
  String get displayName => name.trim().isEmpty ? id : name;

  /// Letters and digits from [value], used to compare names like `BM59` and `BM 59`.
  static String normalize(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static Iterable<String> _tokens(String value) => value
      .toUpperCase()
      .split(RegExp(r'[^A-Z0-9]+'))
      .where((token) => token.isNotEmpty);

  /// Whether this entry refers to [deviceId] or [deviceName].
  ///
  /// Names are compared after stripping spaces and punctuation so a stored
  /// `BM59` still matches an advertised `BM 59`.
  bool matches(String deviceId, [String? deviceName]) {
    if (id == deviceId || name == deviceId) return true;
    if (deviceName != null && (id == deviceName || name == deviceName)) {
      return true;
    }

    final stored = {
      normalize(id),
      normalize(name),
    }.where((value) => value.isNotEmpty).toSet();
    final seen = {
      normalize(deviceId),
      if (deviceName != null) normalize(deviceName),
    }.where((value) => value.isNotEmpty).toSet();

    for (final candidate in seen) {
      for (final known in stored) {
        if (candidate == known) return true;
      }
    }

    final storedTokens = {..._tokens(id), ..._tokens(name)};
    final seenTokens = {
      ..._tokens(deviceId),
      if (deviceName != null) ..._tokens(deviceName),
    };
    for (final known in stored) {
      if (known.length >= 4 && seenTokens.contains(known)) return true;
    }
    for (final candidate in seen) {
      if (candidate.length >= 4 && storedTokens.contains(candidate)) return true;
    }
    return false;
  }

  /// Copy with selected fields replaced.
  KnownBleDevice copyWith({
    String? id,
    String? name,
    bool? autoSync,
  }) =>
      KnownBleDevice(
        id: id ?? this.id,
        name: name ?? this.name,
        autoSync: autoSync ?? this.autoSync,
      );

  /// Serialize for settings storage.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'autoSync': autoSync,
  };

  @override
  bool operator ==(Object other) =>
      other is KnownBleDevice
      && other.id == id
      && other.name == name
      && other.autoSync == autoSync;

  @override
  int get hashCode => Object.hash(id, name, autoSync);

  @override
  String toString() =>
      'KnownBleDevice(id: $id, name: $name, autoSync: $autoSync)';
}
