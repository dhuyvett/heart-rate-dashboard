import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gender.dart';
import '../models/heart_rate_zone.dart';
import '../providers/settings_provider.dart';
import '../services/bluetooth_service.dart';
import '../utils/heart_rate_zone_calculator.dart';
import 'device_selection_screen.dart';

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
  String? _ageError;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _ageController = TextEditingController(text: settings.age.toString());
  }

  @override
  void dispose() {
    _ageController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final maxHr = HeartRateZoneCalculator.calculateMaxHeartRate(
      settings.age,
      settings.gender,
    );
    final zoneRanges = HeartRateZoneCalculator.getZoneRanges(
      settings.age,
      settings.gender,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Personal Information Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Used to calculate your maximum heart rate and training zones',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                    'Gender',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<Gender>(
                    segments: Gender.values.map((gender) {
                      return ButtonSegment<Gender>(
                        value: gender,
                        label: Text(gender.label),
                        icon: Icon(
                          gender == Gender.male ? Icons.male : Icons.female,
                        ),
                      );
                    }).toList(),
                    selected: {settings.gender},
                    onSelectionChanged: (Set<Gender> newSelection) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateGender(newSelection.first);
                    },
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
                            'Maximum Heart Rate: $maxHr BPM\n(Calculated as 220 - age)',
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
                    'Training zones based on your age (${settings.age} years)',
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

          const SizedBox(height: 16),

          // Device Selection Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bluetooth Device',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Change or reconnect to a different heart rate monitor',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToDeviceSelection(context),
                      icon: const Icon(Icons.bluetooth_searching),
                      label: const Text('Change Device'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Navigates to the device selection screen.
  Future<void> _navigateToDeviceSelection(BuildContext context) async {
    // Disconnect from current device
    await BluetoothService.instance.disconnect();

    if (context.mounted) {
      // Navigate to device selection, clearing the navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DeviceSelectionScreen()),
        (route) => false,
      );
    }
  }
}
