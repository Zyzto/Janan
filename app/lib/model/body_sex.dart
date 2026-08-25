/// Biological sex used for Eufy body-composition estimates.
enum BodySex {
  /// Female (Holtek / Eufy `htSex = 0`).
  female,

  /// Male (Holtek / Eufy `htSex = 1`).
  male;

  /// Restore from [serialized].
  static BodySex? deserialize(int? value) => switch (value) {
    0 => BodySex.female,
    1 => BodySex.male,
    _ => null,
  };

  /// Create a [BodySex.deserialize]able number.
  int get serialized => switch (this) {
    BodySex.female => 0,
    BodySex.male => 1,
  };
}
