import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../models/max_hr_calculation_method.dart';
import '../models/monitoring_chart_type.dart';
import '../models/session_statistic.dart';
import '../models/sex.dart';
import '../services/database_service.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';

/// Notifier for managing application settings.
///
/// This notifier loads settings from the database on initialization
/// and persists any changes immediately back to the database.
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static final _logger = AppLogger.getLogger('SettingsNotifier');
  DatabaseService get _databaseService => DatabaseService.instance;

  /// Map for converting string storage format to MaxHRCalculationMethod enum
  static const _maxHRMethodFromString = {
    'custom': MaxHRCalculationMethod.custom,
    'hunt_formula': MaxHRCalculationMethod.huntFormula,
    'tanaka_formula': MaxHRCalculationMethod.tanakaFormula,
    'shargal_formula': MaxHRCalculationMethod.shargalFormula,
    'fox_formula': MaxHRCalculationMethod.foxFormula,
  };

  /// Map for converting MaxHRCalculationMethod enum to string storage format
  static const _maxHRMethodToString = {
    MaxHRCalculationMethod.custom: 'custom',
    MaxHRCalculationMethod.huntFormula: 'hunt_formula',
    MaxHRCalculationMethod.tanakaFormula: 'tanaka_formula',
    MaxHRCalculationMethod.shargalFormula: 'shargal_formula',
    MaxHRCalculationMethod.foxFormula: 'fox_formula',
  };

  /// Storage key for the visible statistics preference.
  static const _visibleStatsKey = 'visible_session_stats';
  static const _monitoringChartKey = 'monitoring_chart_type';

  static const _monitoringChartFromString = {
    'heart_rate': MonitoringChartType.heartRate,
    'zone_time': MonitoringChartType.zoneTime,
  };

  static const _monitoringChartToString = {
    MonitoringChartType.heartRate: 'heart_rate',
    MonitoringChartType.zoneTime: 'zone_time',
  };

  @override
  Future<AppSettings> build() async => _loadSettings();

  /// Loads settings from the database.
  ///
  /// If no settings are found, uses the default values.
  Future<AppSettings> _loadSettings() async {
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
      final showDemoDeviceString = await _databaseService.getSetting(
        'show_demo_device',
      );
      final visibleStatsString = await _databaseService.getSetting(
        _visibleStatsKey,
      );
      final useMilesString = await _databaseService.getSetting('use_miles');
      final monitoringChartString = await _databaseService.getSetting(
        _monitoringChartKey,
      );

      final age = ageString != null ? int.tryParse(ageString) : null;
      final chartWindowSeconds = chartWindowString != null
          ? int.tryParse(chartWindowString)
          : null;
      final keepScreenAwake = keepScreenAwakeString == 'true';
      final darkMode = darkModeString == 'true';
      final sex = sexString == 'female' ? Sex.female : Sex.male;
      final maxHRMethod =
          _maxHRMethodFromString[maxHRMethodString] ??
          MaxHRCalculationMethod.foxFormula;
      final customMaxHR = customMaxHRString != null
          ? int.tryParse(customMaxHRString)
          : null;
      final sessionRetentionDays = sessionRetentionDaysString != null
          ? int.tryParse(sessionRetentionDaysString)
          : null;
      final visibleStats =
          _parseVisibleStats(visibleStatsString) ?? defaultSessionStatistics;
      final useMiles = useMilesString == 'true';
      final showDemoDevice = showDemoDeviceString == 'true';
      final monitoringChartType =
          _monitoringChartFromString[monitoringChartString] ??
          MonitoringChartType.heartRate;

      return AppSettings(
        age: age ?? defaultAge,
        sex: sex,
        maxHRCalculationMethod: maxHRMethod,
        customMaxHR: customMaxHR,
        chartWindowSeconds: chartWindowSeconds ?? defaultChartWindowSeconds,
        keepScreenAwake: keepScreenAwake,
        darkMode: darkMode,
        sessionRetentionDays: sessionRetentionDays ?? 30,
        visibleSessionStats: visibleStats,
        useMiles: useMiles,
        showDemoDevice: showDemoDevice,
        monitoringChartType: monitoringChartType,
      );
    } catch (e, stackTrace) {
      _logger.e('Error loading settings', error: e, stackTrace: stackTrace);
      // propagate to AsyncValue.error
      rethrow;
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

    final current = await future;
    state = AsyncData(current.copyWith(age: age));
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

    final current = await future;
    state = AsyncData(current.copyWith(chartWindowSeconds: seconds));
    await _databaseService.setSetting(
      'chart_window_seconds',
      seconds.toString(),
    );
  }

  /// Updates the keep screen awake setting.
  ///
  /// The change is persisted immediately to the database.
  Future<void> updateKeepScreenAwake(bool enabled) async {
    final current = await future;
    state = AsyncData(current.copyWith(keepScreenAwake: enabled));
    await _databaseService.setSetting('keep_screen_awake', enabled.toString());
  }

  /// Updates the dark mode setting.
  ///
  /// The change is persisted immediately to the database.
  Future<void> updateDarkMode(bool enabled) async {
    final current = await future;
    state = AsyncData(current.copyWith(darkMode: enabled));
    await _databaseService.setSetting('dark_mode', enabled.toString());
  }

  /// Updates the sex setting.
  ///
  /// The change is persisted immediately to the database.
  Future<void> updateSex(Sex sex) async {
    final current = await future;
    state = AsyncData(current.copyWith(sex: sex));
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
    final current = await future;
    state = AsyncData(current.copyWith(maxHRCalculationMethod: method));
    await _databaseService.setSetting(
      'max_hr_calculation_method',
      _maxHRMethodToString[method] ?? 'fox_formula',
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

    final current = await future;
    state = AsyncData(current.copyWith(customMaxHR: maxHR));
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

    final current = await future;
    state = AsyncData(current.copyWith(sessionRetentionDays: days));
    await _databaseService.setSetting(
      'session_retention_days',
      days.toString(),
    );
  }

  /// Updates which statistics appear on the monitoring screen.
  ///
  /// At least one statistic must be selected to avoid an empty layout.
  Future<void> updateVisibleSessionStats(List<SessionStatistic> stats) async {
    if (stats.isEmpty) {
      throw ArgumentError('At least one statistic must be selected');
    }

    final orderedStats = _orderStats(stats);
    final current = await future;
    state = AsyncData(current.copyWith(visibleSessionStats: orderedStats));
    await _databaseService.setSetting(
      _visibleStatsKey,
      orderedStats.map((stat) => stat.name).join(','),
    );
  }

  /// Toggle miles/kilometers for speed/distance.
  Future<void> updateUseMiles(bool useMiles) async {
    final current = await future;
    state = AsyncData(current.copyWith(useMiles: useMiles));
    await _databaseService.setSetting('use_miles', useMiles.toString());
  }

  /// Toggle showing the demo mode device in the device list.
  Future<void> updateShowDemoDevice(bool enabled) async {
    final current = await future;
    state = AsyncData(current.copyWith(showDemoDevice: enabled));
    await _databaseService.setSetting('show_demo_device', enabled.toString());
  }

  /// Updates which chart appears on the monitoring screen.
  Future<void> updateMonitoringChartType(MonitoringChartType chartType) async {
    final current = await future;
    state = AsyncData(current.copyWith(monitoringChartType: chartType));
    await _databaseService.setSetting(
      _monitoringChartKey,
      _monitoringChartToString[chartType] ?? 'heart_rate',
    );
  }

  List<SessionStatistic>? _parseVisibleStats(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    final parsed = <SessionStatistic>[];
    final names = raw
        .split(',')
        .map((s) => s.trim())
        .where((name) => name.isNotEmpty);

    for (final name in names) {
      try {
        parsed.add(
          SessionStatistic.values.firstWhere((stat) => stat.name == name),
        );
      } catch (_) {
        continue;
      }
    }

    if (parsed.isEmpty) return null;
    return _orderStats(parsed);
  }

  List<SessionStatistic> _orderStats(List<SessionStatistic> stats) {
    final set = stats.toSet();
    // Preserve a consistent order for display and storage
    return SessionStatistic.values.where(set.contains).toList();
  }
}

/// Provider for application settings.
///
/// Exposes the current settings state and methods to update them.
/// Settings are automatically persisted to the encrypted database.
final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  () {
    return SettingsNotifier();
  },
);
