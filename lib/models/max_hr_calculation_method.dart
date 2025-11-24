/// Enum representing the method for calculating maximum heart rate.
enum MaxHRCalculationMethod {
  /// Fox Formula: 220 - age (for both men and women)
  foxFormula,

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
      case MaxHRCalculationMethod.custom:
        return 'Custom';
    }
  }

  /// Returns a short label for the calculation method.
  String get shortLabel {
    switch (this) {
      case MaxHRCalculationMethod.foxFormula:
        return 'Fox Formula';
      case MaxHRCalculationMethod.custom:
        return 'Custom';
    }
  }
}
