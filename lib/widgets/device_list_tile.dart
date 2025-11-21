import 'package:flutter/material.dart';
import '../models/scanned_device.dart';

/// A list tile widget that displays a Bluetooth device.
///
/// Shows the device name and signal strength indicator.
/// Demo mode devices have special styling with a distinct icon.
class DeviceListTile extends StatelessWidget {
  /// The scanned device to display.
  final ScannedDevice device;

  /// Callback when the device is tapped.
  final VoidCallback onTap;

  /// Creates a device list tile.
  const DeviceListTile({required this.device, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          device.isDemo ? Icons.psychology : Icons.bluetooth,
          color: device.isDemo
              ? theme.colorScheme.secondary
              : theme.colorScheme.primary,
          size: 32,
        ),
        title: Text(
          device.name,
          style: device.isDemo
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                )
              : theme.textTheme.titleMedium,
        ),
        subtitle: device.isDemo
            ? Text(
                'Simulated heart rate data for testing',
                style: theme.textTheme.bodySmall,
              )
            : null,
        trailing: device.isDemo
            ? null
            : _SignalStrengthIndicator(rssi: device.rssi),
      ),
    );
  }
}

/// Displays signal strength as a series of bars.
///
/// The number of filled bars represents the signal strength:
/// - 1 bar: Very weak (-90 dBm or weaker)
/// - 2 bars: Weak (-80 to -90 dBm)
/// - 3 bars: Medium (-70 to -80 dBm)
/// - 4 bars: Good (-60 to -70 dBm)
/// - 5 bars: Excellent (-60 dBm or stronger)
class _SignalStrengthIndicator extends StatelessWidget {
  final int rssi;

  const _SignalStrengthIndicator({required this.rssi});

  @override
  Widget build(BuildContext context) {
    final bars = _getSignalBars(rssi);
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < bars;
        final height = 12.0 + (index * 3.0);

        return Container(
          width: 4,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isFilled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  /// Converts RSSI value to number of signal bars (1-5).
  int _getSignalBars(int rssi) {
    if (rssi >= -60) return 5;
    if (rssi >= -70) return 4;
    if (rssi >= -80) return 3;
    if (rssi >= -90) return 2;
    return 1;
  }
}
