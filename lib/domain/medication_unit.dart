/// Unit for a medicine dose.
enum MedicationUnit {
  /// Milligrams.
  mg,

  /// Micrograms.
  mcg,

  /// Grams.
  g,

  /// International units.
  iu,

  /// Tablets or pills.
  tablet,

  /// Milliliters.
  ml;

  /// Short label shown next to a dose.
  String get symbol => switch (this) {
    MedicationUnit.mg => 'mg',
    MedicationUnit.mcg => 'mcg',
    MedicationUnit.g => 'g',
    MedicationUnit.iu => 'IU',
    MedicationUnit.tablet => 'tab',
    MedicationUnit.ml => 'ml',
  };

  /// Localization key for the full unit name.
  String get labelKey => switch (this) {
    MedicationUnit.mg => 'unitMg',
    MedicationUnit.mcg => 'unitMcg',
    MedicationUnit.g => 'unitG',
    MedicationUnit.iu => 'unitIu',
    MedicationUnit.tablet => 'unitTablet',
    MedicationUnit.ml => 'unitMl',
  };

  /// Parse a stored unit name, defaulting to milligrams.
  static MedicationUnit parse(Object? raw) {
    final name = raw?.toString();
    if (name == null || name.isEmpty) return MedicationUnit.mg;
    return MedicationUnit.values.asNameMap()[name] ?? MedicationUnit.mg;
  }
}

/// Format a numeric dose without trailing `.0`.
String formatDoseAmount(double amount) {
  if (amount == amount.roundToDouble()) return amount.toInt().toString();
  return amount.toString();
}

/// Format [amount] with [unit], e.g. `5 mg` or `1 tab`.
String formatMedicationDose(double? amount, [MedicationUnit unit = MedicationUnit.mg]) {
  if (amount == null) return '';
  return '${formatDoseAmount(amount)} ${unit.symbol}';
}
