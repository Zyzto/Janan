import 'package:blood_pressure_app/model/body_sex.dart';
import 'package:blood_pressure_app/model/storage/convert_util.dart';
import 'package:settings_annotation/settings_annotation.dart';

/// A [BodySex] setting that may be unset.
class BodySexSetting extends Setting<BodySex?> {
  /// Create a nullable sex setting.
  BodySexSetting({required super.initialValue});

  @override
  Object? toMapValue() => value?.serialized;

  @override
  void fromMapValue(Object? value) {
    this.value = value == null
        ? null
        : BodySex.deserialize(ConvertUtil.parseInt(value));
  }
}
