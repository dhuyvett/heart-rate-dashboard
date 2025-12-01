import 'package:heart_rate_dashboard/models/app_settings.dart';
import 'package:heart_rate_dashboard/models/max_hr_calculation_method.dart';
import 'package:heart_rate_dashboard/models/sex.dart';
import 'package:heart_rate_dashboard/providers/settings_provider.dart';

/// In-memory SettingsNotifier used for widget/integration tests to avoid
/// touching the real database service.
class FakeSettingsNotifier extends SettingsNotifier {
  FakeSettingsNotifier(this._initial);

  final AppSettings _initial;

  int? lastAge;
  int? lastChartWindow;
  bool? lastKeepAwake;
  bool? lastDarkMode;
  Sex? lastSex;
  MaxHRCalculationMethod? lastMethod;
  int? lastCustomMaxHr;
  int? lastRetentionDays;

  @override
  AppSettings build() => _initial;

  @override
  Future<void> updateAge(int age) async {
    state = state.copyWith(age: age);
    lastAge = age;
  }

  @override
  Future<void> updateChartWindow(int seconds) async {
    state = state.copyWith(chartWindowSeconds: seconds);
    lastChartWindow = seconds;
  }

  @override
  Future<void> updateKeepScreenAwake(bool enabled) async {
    state = state.copyWith(keepScreenAwake: enabled);
    lastKeepAwake = enabled;
  }

  @override
  Future<void> updateDarkMode(bool enabled) async {
    state = state.copyWith(darkMode: enabled);
    lastDarkMode = enabled;
  }

  @override
  Future<void> updateSex(Sex sex) async {
    state = state.copyWith(sex: sex);
    lastSex = sex;
  }

  @override
  Future<void> updateMaxHRCalculationMethod(
    MaxHRCalculationMethod method,
  ) async {
    state = state.copyWith(maxHRCalculationMethod: method);
    lastMethod = method;
  }

  @override
  Future<void> updateCustomMaxHR(int maxHR) async {
    state = state.copyWith(customMaxHR: maxHR);
    lastCustomMaxHr = maxHR;
  }

  @override
  Future<void> updateSessionRetentionDays(int days) async {
    state = state.copyWith(sessionRetentionDays: days);
    lastRetentionDays = days;
  }
}
