/// Enum representing biological sex for heart rate calculations.
///
/// Used to calculate more accurate maximum heart rate values:
/// - Male: 214 - (0.8 × age)
/// - Female: 209 - (0.9 × age)
enum Gender {
  /// Male biological sex
  male,

  /// Female biological sex
  female,
}

/// Extension to provide display labels for gender values.
extension GenderExtension on Gender {
  /// Returns a user-friendly display label for the gender.
  String get label {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
    }
  }
}
