import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/heart_rate_zone.dart';
import '../models/max_hr_calculation_method.dart';
import '../models/sex.dart';
import '../providers/settings_provider.dart';
import '../utils/heart_rate_zone_calculator.dart';
import 'max_hr_info_screen.dart';

/// Settings screen for configuring app preferences.
///
/// Allows users to:
/// - Set their age for heart rate zone calculations
/// - Configure the chart time window
/// - View calculated heart rate zones
///
/// All changes are saved immediately to the encrypted database.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _ageController;
  late TextEditingController _customMaxHRController;
  late TextEditingController _retentionDaysController;
  String? _ageError;
  String? _customMaxHRError;
  String? _retentionDaysError;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _ageController = TextEditingController(text: settings.age.toString());
    _customMaxHRController = TextEditingController(
      text: settings.customMaxHR?.toString() ?? '',
    );
    _retentionDaysController = TextEditingController(
      text: settings.sessionRetentionDays.toString(),
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _customMaxHRController.dispose();
    _retentionDaysController.dispose();
    super.dispose();
  }

  /// Updates the age setting.
  Future<void> _updateAge(String value) async {
    final age = int.tryParse(value);

    if (age == null) {
      setState(() {
        _ageError = 'Please enter a valid number';
      });
      return;
    }

    if (age < 10 || age > 100) {
      setState(() {
        _ageError = 'Age must be between 10 and 100';
      });
      return;
    }

    setState(() {
      _ageError = null;
    });

    try {
      await ref.read(settingsProvider.notifier).updateAge(age);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating age: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Updates the chart window setting.
  Future<void> _updateChartWindow(int seconds) async {
    try {
      await ref.read(settingsProvider.notifier).updateChartWindow(seconds);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating chart window: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Updates the custom max HR setting.
  Future<void> _updateCustomMaxHR(String value) async {
    final maxHR = int.tryParse(value);

    if (maxHR == null) {
      setState(() {
        _customMaxHRError = 'Please enter a valid number';
      });
      return;
    }

    if (maxHR < 100 || maxHR > 220) {
      setState(() {
        _customMaxHRError = 'Max HR must be between 100 and 220';
      });
      return;
    }

    setState(() {
      _customMaxHRError = null;
    });

    try {
      await ref.read(settingsProvider.notifier).updateCustomMaxHR(maxHR);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating custom max HR: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Updates the session retention days setting.
  Future<void> _updateRetentionDays(String value) async {
    final days = int.tryParse(value);

    if (days == null) {
      setState(() {
        _retentionDaysError = 'Please enter a valid number';
      });
      return;
    }

    if (days < 1 || days > 3650) {
      setState(() {
        _retentionDaysError = 'Must be between 1 and 3650 days';
      });
      return;
    }

    setState(() {
      _retentionDaysError = null;
    });

    try {
      await ref
          .read(settingsProvider.notifier)
          .updateSessionRetentionDays(days);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating retention days: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final maxHr = HeartRateZoneCalculator.calculateMaxHeartRate(settings);
    final zoneRanges = HeartRateZoneCalculator.getZoneRanges(settings);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Max Heart Rate Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Max Heart Rate',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Used to calculate your training zones',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Max Heart Rate Calculation',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.info_outline, size: 20),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const MaxHRInfoScreen(),
                            ),
                          );
                        },
                        tooltip: 'Learn about calculation methods',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MaxHRCalculationMethod>(
                    initialValue: settings.maxHRCalculationMethod,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    isExpanded: true,
                    isDense: true,
                    itemHeight: null,
                    selectedItemBuilder: (BuildContext context) {
                      return MaxHRCalculationMethod.values.map((method) {
                        return Text(
                          method.shortLabel,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        );
                      }).toList();
                    },
                    items: MaxHRCalculationMethod.values.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(
                          method.label,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      );
                    }).toList(),
                    onChanged: (method) {
                      if (method != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .updateMaxHRCalculationMethod(method);
                      }
                    },
                  ),
                  if (settings.maxHRCalculationMethod ==
                      MaxHRCalculationMethod.custom) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customMaxHRController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Custom Max HR (BPM)',
                        border: const OutlineInputBorder(),
                        errorText: _customMaxHRError,
                        hintText: '100-220',
                      ),
                      onChanged: _updateCustomMaxHR,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled:
                        settings.maxHRCalculationMethod !=
                        MaxHRCalculationMethod.custom,
                    decoration: InputDecoration(
                      labelText: 'Age (years)',
                      border: const OutlineInputBorder(),
                      errorText: _ageError,
                      suffixIcon: const Icon(Icons.person),
                    ),
                    onChanged: _updateAge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sex',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Used for sex-specific heart rate formulas',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<Sex>(
                    segments: Sex.values.map((sex) {
                      return ButtonSegment<Sex>(
                        value: sex,
                        label: Text(sex.label),
                        icon: Icon(sex == Sex.male ? Icons.male : Icons.female),
                      );
                    }).toList(),
                    selected: {settings.sex},
                    onSelectionChanged:
                        settings.maxHRCalculationMethod ==
                            MaxHRCalculationMethod.shargalFormula
                        ? (Set<Sex> newSelection) {
                            ref
                                .read(settingsProvider.notifier)
                                .updateSex(newSelection.first);
                          }
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Maximum Heart Rate: $maxHr BPM',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Heart Rate Zones Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Heart Rate Zones',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Training zones based on your maximum heart rate of $maxHr BPM',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...HeartRateZone.values.map((zone) {
                    final range = zoneRanges[zone]!;
                    final color = HeartRateZoneCalculator.getColorForZone(zone);
                    final label = HeartRateZoneCalculator.getZoneLabel(zone);
                    final percentage =
                        HeartRateZoneCalculator.getZonePercentageRange(zone);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: color.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$percentage: ${range.$1}-${range.$2} BPM',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Chart Time Window Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chart Time Window',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How many seconds of heart rate history to display on the chart',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [15, 30, 45, 60].map((seconds) {
                      final isSelected = settings.chartWindowSeconds == seconds;
                      return ChoiceChip(
                        label: Text('${seconds}s'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            _updateChartWindow(seconds);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Session Retention Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session Retention',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sessions older than this will be automatically deleted',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _retentionDaysController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Session Retention (days)',
                      border: const OutlineInputBorder(),
                      errorText: _retentionDaysError,
                      hintText: '1-3650',
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    onChanged: _updateRetentionDays,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Keep Screen Awake Section
          Card(
            child: SwitchListTile(
              title: Text(
                'Keep Screen Awake',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Prevent screen from sleeping while monitoring heart rate',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              value: settings.keepScreenAwake,
              onChanged: (value) async {
                await ref
                    .read(settingsProvider.notifier)
                    .updateKeepScreenAwake(value);
              },
            ),
          ),

          const SizedBox(height: 16),

          // Dark Mode Section
          Card(
            child: SwitchListTile(
              title: Text(
                'Dark Mode',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Use dark color scheme throughout the app',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              value: settings.darkMode,
              onChanged: (value) async {
                await ref.read(settingsProvider.notifier).updateDarkMode(value);
              },
              secondary: Icon(
                settings.darkMode ? Icons.dark_mode : Icons.light_mode,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
