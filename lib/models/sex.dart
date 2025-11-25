/// Enum representing biological sex for heart rate calculations.
///
/// Used to calculate more accurate maximum heart rate values:
/// - Male: 208.609 - (0.71 × age)
/// - Female: 209.273 - (0.804 × age)
enum Sex {
  /// Male biological sex
  male,

  /// Female biological sex
  female,
}

/// Extension to provide display labels for sex values.
extension SexExtension on Sex {
  /// Returns a user-friendly display label for the sex.
  String get label {
    switch (this) {
      case Sex.male:
        return 'Male';
      case Sex.female:
        return 'Female';
    }
  }
}
