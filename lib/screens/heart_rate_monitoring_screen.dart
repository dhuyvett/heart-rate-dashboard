import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/heart_rate_data.dart';
import '../models/heart_rate_reading.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/heart_rate_provider.dart';
import '../providers/session_provider.dart';
import '../providers/settings_provider.dart';
import '../services/bluetooth_service.dart' as bt;
import '../services/database_service.dart';
import '../services/reconnection_handler.dart';
import '../utils/heart_rate_zone_calculator.dart';
import '../widgets/connection_status_indicator.dart';
import '../widgets/error_dialog.dart';
import '../widgets/heart_rate_chart.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/session_stats_card.dart';
import 'device_selection_screen.dart';
import 'settings_screen.dart';

/// Main screen for monitoring heart rate in real-time.
///
/// Displays a large, color-coded BPM value, a scrolling line chart,
/// and session statistics. Updates continuously as new heart rate
/// data arrives from the connected device.
class HeartRateMonitoringScreen extends ConsumerStatefulWidget {
  /// The name of the connected device.
  final String deviceName;

  const HeartRateMonitoringScreen({required this.deviceName, super.key});

  @override
  ConsumerState<HeartRateMonitoringScreen> createState() =>
      _HeartRateMonitoringScreenState();
}

class _HeartRateMonitoringScreenState
    extends ConsumerState<HeartRateMonitoringScreen> {
  List<HeartRateReading> _recentReadings = [];
  bool _sessionStarted = false;
  int? _lastKnownBpm;
  StreamSubscription<ReconnectionState>? _reconnectionSubscription;
  ReconnectionState _reconnectionState = ReconnectionState.idle();

  @override
  void initState() {
    super.initState();
    _startSession();
    _setupReconnectionListener();
  }

  @override
  void dispose() {
    _reconnectionSubscription?.cancel();
    super.dispose();
  }

  /// Sets up the reconnection state listener.
  void _setupReconnectionListener() {
    _reconnectionSubscription = ReconnectionHandler.instance.stateStream.listen(
      (state) {
        if (mounted) {
          setState(() {
            _reconnectionState = state;
          });

          // If all attempts failed, show the failure dialog
          if (state.hasFailed) {
            _showReconnectionFailedDialog();
          }
        }
      },
    );
  }

  /// Shows the reconnection failed dialog with retry/select device options.
  Future<void> _showReconnectionFailedDialog() async {
    final shouldRetry = await showConnectionFailedDialog(
      context: context,
      attemptCount: _reconnectionState.maxAttempts,
    );

    if (mounted) {
      if (shouldRetry) {
        // Retry reconnection
        await ReconnectionHandler.instance.retryReconnection();
      } else {
        // End session and go to device selection
        await _endSessionAndNavigateToDeviceSelection();
      }
    }
  }

  /// Ends the current session and navigates to device selection.
  Future<void> _endSessionAndNavigateToDeviceSelection() async {
    ReconnectionHandler.instance.stopMonitoring();
    await ref.read(sessionProvider.notifier).endSession();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DeviceSelectionScreen()),
      );
    }
  }

  /// Starts a new workout session.
  Future<void> _startSession() async {
    if (!_sessionStarted) {
      _sessionStarted = true;
      await ref.read(sessionProvider.notifier).startSession(widget.deviceName);

      // Set up reconnection monitoring
      final bluetoothService = bt.BluetoothService.instance;
      if (!bluetoothService.isInDemoMode) {
        // Start monitoring for reconnection (not needed for demo mode)
        final lastDeviceId = await DatabaseService.instance.getSetting(
          'last_connected_device_id',
        );
        if (lastDeviceId != null && lastDeviceId.isNotEmpty) {
          ReconnectionHandler.instance.setSessionIdToResume(
            ref.read(sessionProvider).currentSessionId,
          );
          ReconnectionHandler.instance.startMonitoring(lastDeviceId);
        }
      }

      _loadRecentReadings();
    }
  }

  /// Loads recent readings from the database for the chart.
  Future<void> _loadRecentReadings() async {
    final sessionState = ref.read(sessionProvider);
    if (sessionState.currentSessionId == null) return;

    final settings = ref.read(settingsProvider);
    final windowStart = DateTime.now().subtract(
      Duration(seconds: settings.chartWindowSeconds),
    );

    try {
      final readings = await DatabaseService.instance
          .getReadingsBySessionAndTimeRange(
            sessionState.currentSessionId!,
            windowStart,
            DateTime.now(),
          );

      if (mounted) {
        setState(() {
          _recentReadings = readings;
        });
      }
    } catch (e) {
      // Log error but continue - chart will show available data
      debugPrint('Error loading recent readings: $e');
    }
  }

  /// Formats duration as HH:MM:SS.
  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final heartRateAsync = ref.watch(heartRateProvider);
    final sessionState = ref.watch(sessionProvider);
    final connectionAsync = ref.watch(bluetoothConnectionProvider);

    // Periodically reload readings for the chart and track last known BPM
    ref.listen(heartRateProvider, (previous, next) {
      if (next is AsyncData<HeartRateData>) {
        _lastKnownBpm = next.value.bpm;
        ReconnectionHandler.instance.setLastKnownBpm(next.value.bpm);
        _loadRecentReadings();
      }
    });

    // Check if we're reconnecting
    final isReconnecting = _reconnectionState.isReconnecting;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceName),
        automaticallyImplyLeading: false,
        leading: connectionAsync.when(
          data: (connectionInfo) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConnectionStatusIndicator(
              connectionState: isReconnecting
                  ? bt.ConnectionState.reconnecting
                  : connectionInfo.connectionState,
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Large BPM Display
                _buildBpmDisplay(
                  theme: theme,
                  heartRateAsync: heartRateAsync,
                  isReconnecting: isReconnecting,
                ),

                const SizedBox(height: 32),

                // Heart Rate Chart
                SizedBox(
                  height: 250,
                  child: heartRateAsync.when(
                    data: (hrData) {
                      final color = HeartRateZoneCalculator.getColorForZone(
                        hrData.zone,
                      );
                      return HeartRateChart(
                        readings: _recentReadings,
                        windowSeconds: settings.chartWindowSeconds,
                        lineColor: isReconnecting
                            ? color.withValues(alpha: 0.5)
                            : color,
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text(
                        'Chart unavailable',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Session Statistics
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Statistics',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          SessionStatsCard(
                            icon: Icons.timer,
                            label: 'Duration',
                            value: _formatDuration(sessionState.duration),
                          ),
                          SessionStatsCard(
                            icon: Icons.favorite,
                            label: 'Average',
                            value: sessionState.avgHr != null
                                ? '${sessionState.avgHr}'
                                : '--',
                          ),
                          SessionStatsCard(
                            icon: Icons.arrow_downward,
                            label: 'Minimum',
                            value: sessionState.minHr != null
                                ? '${sessionState.minHr}'
                                : '--',
                            iconColor: Colors.blue,
                          ),
                          SessionStatsCard(
                            icon: Icons.arrow_upward,
                            label: 'Maximum',
                            value: sessionState.maxHr != null
                                ? '${sessionState.maxHr}'
                                : '--',
                            iconColor: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),

          // Reconnection overlay
          if (isReconnecting)
            ReconnectionOverlay(
              currentAttempt: _reconnectionState.currentAttempt,
              maxAttempts: _reconnectionState.maxAttempts,
              lastKnownBpm: _lastKnownBpm ?? _reconnectionState.lastKnownBpm,
            ),
        ],
      ),
    );
  }

  /// Builds the large BPM display widget with smooth animations.
  Widget _buildBpmDisplay({
    required ThemeData theme,
    required AsyncValue heartRateAsync,
    required bool isReconnecting,
  }) {
    // If reconnecting, show the last known BPM in a dimmed state
    if (isReconnecting && _lastKnownBpm != null) {
      return Column(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: 0.3,
            child: Text(
              _lastKnownBpm.toString(),
              style: TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'BPM',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Reconnecting...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      );
    }

    return heartRateAsync.when(
      data: (hrData) {
        final color = HeartRateZoneCalculator.getColorForZone(hrData.zone);
        final zoneLabel = HeartRateZoneCalculator.getZoneLabel(hrData.zone);

        return Column(
          children: [
            // Animated BPM value with smooth number transitions
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: AnimatedDefaultTextStyle(
                key: ValueKey<int>(hrData.bpm),
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                child: Text(hrData.bpm.toString()),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'BPM',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            // Animated zone label with smooth color transitions
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: theme.textTheme.titleMedium!.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                child: Text(zoneLabel),
              ),
            ),
          ],
        );
      },
      loading: () => Column(
        children: [
          Text(
            '---',
            style: TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Waiting for data...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      error: (error, stack) => Column(
        children: [
          Text(
            '---',
            style: TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connection error',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
