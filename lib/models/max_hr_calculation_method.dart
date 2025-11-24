/// Enum representing the method for calculating maximum heart rate.
enum MaxHRCalculationMethod {
  /// Fox Formula: 220 - age (for both men and women)
  foxFormula,

  /// HUNT Formula: 211 - (0.64 × age) (for both men and women)
  huntFormula,

  /// Tanaka Formula: 208 - (0.7 × age) (for both men and women)
  tanakaFormula,

  /// Shargal Formula: 208.609 - (0.71 × age) for men, 209.273 - (0.804 × age) for women
  shargalFormula,

  /// Custom value entered by the user
  custom,
}

/// Extension to provide display labels for max HR calculation methods.
extension MaxHRCalculationMethodExtension on MaxHRCalculationMethod {
  /// Returns a user-friendly display label for the calculation method.
  String get label {
    switch (this) {
      case MaxHRCalculationMethod.foxFormula:
        return 'Fox Formula: 220 - age for both men and women';
      case MaxHRCalculationMethod.huntFormula:
        return 'HUNT Formula: 211 - (0.64 × age) for both men and women';
      case MaxHRCalculationMethod.tanakaFormula:
        return 'Tanaka Formula: 208 - (0.7 × age) for both men and women';
      case MaxHRCalculationMethod.shargalFormula:
        return 'Shargal Formula: 208.609 - (0.71 × age) for men, 209.273 - (0.804 × age) for women';
      case MaxHRCalculationMethod.custom:
        return 'Custom';
    }
  }

  /// Returns a short label for the calculation method.
  String get shortLabel {
    switch (this) {
      case MaxHRCalculationMethod.foxFormula:
        return 'Fox Formula';
      case MaxHRCalculationMethod.huntFormula:
        return 'HUNT Formula';
      case MaxHRCalculationMethod.tanakaFormula:
        return 'Tanaka Formula';
      case MaxHRCalculationMethod.shargalFormula:
        return 'Shargal Formula';
      case MaxHRCalculationMethod.custom:
        return 'Custom';
    }
  }
}
