import 'package:blood_pressure_app/model/storage/convert_util.dart';
import 'package:settings_annotation/settings_annotation.dart';

/// An [int] setting that may be unset.
class NullableIntSetting extends Setting<int?> {
  /// Create a nullable int setting.
  NullableIntSetting({required super.initialValue});

  @override
  Object? toMapValue() => value;

  @override
  void fromMapValue(Object? value) {
    this.value = value == null ? null : ConvertUtil.parseInt(value);
  }
}
