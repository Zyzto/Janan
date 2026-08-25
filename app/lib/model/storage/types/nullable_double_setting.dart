import 'package:blood_pressure_app/model/storage/convert_util.dart';
import 'package:settings_annotation/settings_annotation.dart';

/// A [double] setting that may be unset.
class NullableDoubleSetting extends Setting<double?> {
  /// Create a nullable double setting.
  NullableDoubleSetting({required super.initialValue});

  @override
  Object? toMapValue() => value;

  @override
  void fromMapValue(Object? value) {
    this.value = value == null ? null : ConvertUtil.parseDouble(value);
  }
}
