import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

/// Notifier for managing application settings.
///
/// This notifier loads settings from the database on initialization
/// and persists any changes immediately back to the database.
class SettingsNotifier extends Notifier<AppSettings> {
  DatabaseService get _databaseService => DatabaseService.instance;

  @override
  AppSettings build() {
    // Load settings asynchronously
    _loadSettings();
    // Return default settings initially
    return const AppSettings();
  }

  /// Loads settings from the database.
  ///
  /// If no settings are found, uses the default values.
  Future<void> _loadSettings() async {
    try {
      final ageString = await _databaseService.getSetting('user_age');
      final chartWindowString = await _databaseService.getSetting(
        'chart_window_seconds',
      );
      final keepScreenAwakeString = await _databaseService.getSetting(
        'keep_screen_awake',
      );
      final darkModeString = await _databaseService.getSetting('dark_mode');

      final age = ageString != null ? int.tryParse(ageString) : null;
      final chartWindowSeconds = chartWindowString != null
          ? int.tryParse(chartWindowString)
          : null;
      final keepScreenAwake = keepScreenAwakeString == 'true';
      final darkMode = darkModeString == 'true';

      state = AppSettings(
        age: age ?? defaultAge,
        chartWindowSeconds: chartWindowSeconds ?? defaultChartWindowSeconds,
        keepScreenAwake: keepScreenAwake,
        darkMode: darkMode,
      );
    } catch (e) {
      // If loading fails, keep default settings
      // Log error for debugging
      // ignore: avoid_print
      print('Error loading settings: $e');
    }
  }

  /// Updates the user's age setting.
  ///
  /// The change is persisted immediately to the database.
  /// Valid range: 10-100 years.
  Future<void> updateAge(int age) async {
    if (age < 10 || age > 100) {
      throw ArgumentError('Age must be between 10 and 100, got $age');
    }

    state = state.copyWith(age: age);
    await _databaseService.setSetting('user_age', age.toString());
  }

  /// Updates the chart time window setting.
  ///
  /// The change is persisted immediately to the database.
  /// Valid values: 15, 30, 45, 60 seconds.
  Future<void> updateChartWindow(int seconds) async {
    if (![15, 30, 45, 60].contains(seconds)) {
      throw ArgumentError(
        'Chart window must be 15, 30, 45, or 60 seconds, got $seconds',
      );
    }

    state = state.copyWith(chartWindowSeconds: seconds);
    await _databaseService.setSetting(
      'chart_window_seconds',
      seconds.toString(),
    );
  }

  /// Updates the keep screen awake setting.
  ///
  /// The change is persisted immediately to the database.
  Future<void> updateKeepScreenAwake(bool enabled) async {
    state = state.copyWith(keepScreenAwake: enabled);
    await _databaseService.setSetting('keep_screen_awake', enabled.toString());
  }

  /// Updates the dark mode setting.
  ///
  /// The change is persisted immediately to the database.
  Future<void> updateDarkMode(bool enabled) async {
    state = state.copyWith(darkMode: enabled);
    await _databaseService.setSetting('dark_mode', enabled.toString());
  }
}

/// Provider for application settings.
///
/// Exposes the current settings state and methods to update them.
/// Settings are automatically persisted to the encrypted database.
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});
