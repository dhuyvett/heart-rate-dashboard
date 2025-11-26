import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../models/max_hr_calculation_method.dart';
import '../models/sex.dart';
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
      final sexString = await _databaseService.getSetting('sex');
      final maxHRMethodString = await _databaseService.getSetting(
        'max_hr_calculation_method',
      );
      final customMaxHRString = await _databaseService.getSetting(
        'custom_max_hr',
      );
      final sessionRetentionDaysString = await _databaseService.getSetting(
        'session_retention_days',
      );

      final age = ageString != null ? int.tryParse(ageString) : null;
      final chartWindowSeconds = chartWindowString != null
          ? int.tryParse(chartWindowString)
          : null;
      final keepScreenAwake = keepScreenAwakeString == 'true';
      final darkMode = darkModeString == 'true';
      final sex = sexString == 'female' ? Sex.female : Sex.male;
      final maxHRMethod = maxHRMethodString == 'custom'
          ? MaxHRCalculationMethod.custom
          : maxHRMethodString == 'hunt_formula'
          ? MaxHRCalculationMethod.huntFormula
          : maxHRMethodString == 'tanaka_formula'
          ? MaxHRCalculationMethod.tanakaFormula
          : maxHRMethodString == 'shargal_formula'
          ? MaxHRCalculationMethod.shargalFormula
          : MaxHRCalculationMethod.foxFormula;
      final customMaxHR = customMaxHRString != null
          ? int.tryParse(customMaxHRString)
          : null;
      final sessionRetentionDays = sessionRetentionDaysString != null
          ? int.tryParse(sessionRetentionDaysString)
          : null;

      state = AppSettings(
        age: age ?? defaultAge,
        sex: sex,
        maxHRCalculationMethod: maxHRMethod,
        customMaxHR: customMaxHR,
        chartWindowSeconds: chartWindowSeconds ?? defaultChartWindowSeconds,
        keepScreenAwake: keepScreenAwake,
        darkMode: darkMode,
        sessionRetentionDays: sessionRetentionDays ?? 30,
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

  /// Updates the sex setting.
  ///
  /// The change is persisted immediately to the database.
  Future<void> updateSex(Sex sex) async {
    state = state.copyWith(sex: sex);
    await _databaseService.setSetting(
      'sex',
      sex == Sex.female ? 'female' : 'male',
    );
  }

  /// Updates the max heart rate calculation method.
  ///
  /// The change is persisted immediately to the database.
  Future<void> updateMaxHRCalculationMethod(
    MaxHRCalculationMethod method,
  ) async {
    state = state.copyWith(maxHRCalculationMethod: method);
    await _databaseService.setSetting(
      'max_hr_calculation_method',
      method == MaxHRCalculationMethod.custom
          ? 'custom'
          : method == MaxHRCalculationMethod.huntFormula
          ? 'hunt_formula'
          : method == MaxHRCalculationMethod.tanakaFormula
          ? 'tanaka_formula'
          : method == MaxHRCalculationMethod.shargalFormula
          ? 'shargal_formula'
          : 'fox_formula',
    );
  }

  /// Updates the custom maximum heart rate value.
  ///
  /// The change is persisted immediately to the database.
  /// Valid range: 100-220 BPM.
  Future<void> updateCustomMaxHR(int maxHR) async {
    if (maxHR < 100 || maxHR > 220) {
      throw ArgumentError(
        'Custom max HR must be between 100 and 220, got $maxHR',
      );
    }

    state = state.copyWith(customMaxHR: maxHR);
    await _databaseService.setSetting('custom_max_hr', maxHR.toString());
  }

  /// Updates the session retention days setting.
  ///
  /// The change is persisted immediately to the database.
  /// Valid range: 1-3650 days.
  Future<void> updateSessionRetentionDays(int days) async {
    if (days < 1 || days > 3650) {
      throw ArgumentError(
        'Session retention days must be between 1 and 3650, got $days',
      );
    }

    state = state.copyWith(sessionRetentionDays: days);
    await _databaseService.setSetting(
      'session_retention_days',
      days.toString(),
    );
  }
}

/// Provider for application settings.
///
/// Exposes the current settings state and methods to update them.
/// Settings are automatically persisted to the encrypted database.
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});
