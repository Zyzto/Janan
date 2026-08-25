import 'dart:collection';
import 'dart:convert';

import 'package:blood_pressure_app/model/known_ble_device.dart';
import 'package:blood_pressure_app/model/storage/convert_util.dart';
import 'package:settings_annotation/settings_annotation.dart';

/// Persists [KnownBleDevice]s and migrates the old id-only string list.
class KnownBleDeviceListSetting extends Setting<List<KnownBleDevice>> {
  /// Create a setting that stores remembered bluetooth devices.
  KnownBleDeviceListSetting({required super.initialValue});

  @override
  Object? toMapValue() => value.map((device) => device.toJson()).toList();

  @override
  void fromMapValue(Object? value) => super.fromMapValue(_parse(value));

  @override
  List<KnownBleDevice> get value => UnmodifiableListView(super.value);

  List<KnownBleDevice>? _parse(Object? value) {
    if (value is! List) return ConvertUtil.parseList<KnownBleDevice>(value);

    final devices = <KnownBleDevice>[];
    for (final item in value) {
      final parsed = _parseItem(item);
      if (parsed != null) devices.add(parsed);
    }
    return devices;
  }

  KnownBleDevice? _parseItem(Object? item) {
    if (item is KnownBleDevice) return item;
    if (item is Map) {
      return KnownBleDevice.fromJson(Map<String, dynamic>.from(item));
    }
    if (item is String) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map) {
          return KnownBleDevice.fromJson(Map<String, dynamic>.from(decoded));
        }
      } on FormatException {
        // Legacy entries stored a bare device id or advertised name.
      }
      return KnownBleDevice(id: item, name: item);
    }
    return null;
  }
}
