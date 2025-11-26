import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
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
import '../widgets/compact_stats_row.dart';
import '../widgets/connection_status_indicator.dart';
import '../widgets/error_dialog.dart';
import '../widgets/heart_rate_chart.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/session_stats_card.dart';
import 'about_screen.dart';
import 'device_selection_screen.dart';
import 'session_history_screen.dart';
import 'settings_screen.dart';

/// Main screen for monitoring heart rate in real-time.
///
/// Displays a large, color-coded BPM value, a scrolling line chart,
/// and session statistics. Updates continuously as new heart rate
/// data arrives from the connected device.
///
/// The layout adapts responsively:
/// - Portrait: Vertical stacking with flexible space distribution
/// - Landscape: Side-by-side layout with BPM+chart on left, stats+buttons on right
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
  DateTime? _pausedAt;

  /// Threshold for switching between grid and compact statistics display.
  static const double _statsHeightThreshold = 200.0;

  /// Minimum height for the chart widget.
  static const double _minChartHeight = 100.0;

  /// Fixed height for action buttons.
  static const double _buttonHeight = 44.0;

  @override
  void initState() {
    super.initState();
    _startSession();
    _setupReconnectionListener();
    _updateWakeLock();
  }

  @override
  void dispose() {
    _reconnectionSubscription?.cancel();
    // Always disable wake lock when leaving the screen
    WakelockPlus.disable();
    super.dispose();
  }

  /// Updates the wake lock based on the current setting.
  void _updateWakeLock() {
    final settings = ref.read(settingsProvider);
    if (settings.keepScreenAwake) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
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

  /// Navigates to the device selection screen from the menu.
  Future<void> _navigateToDeviceSelection() async {
    // Disconnect from current device
    await bt.BluetoothService.instance.disconnect();

    // Stop reconnection monitoring
    ReconnectionHandler.instance.stopMonitoring();

    // End the current session
    await ref.read(sessionProvider.notifier).endSession();

    if (mounted) {
      // Navigate to device selection, clearing the navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DeviceSelectionScreen()),
        (route) => false,
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

  /// Determines if the layout should be landscape based on aspect ratio.
  bool _isLandscape(BoxConstraints constraints) {
    return constraints.maxWidth > constraints.maxHeight;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final heartRateAsync = ref.watch(heartRateProvider);
    final sessionState = ref.watch(sessionProvider);
    final connectionAsync = ref.watch(bluetoothConnectionProvider);

    // Periodically reload readings for the chart and track last known BPM
    // Skip updates when session is paused
    ref.listen(heartRateProvider, (previous, next) {
      if (next is AsyncData<HeartRateData> && !sessionState.isPaused) {
        _lastKnownBpm = next.value.bpm;
        ReconnectionHandler.instance.setLastKnownBpm(next.value.bpm);
        _loadRecentReadings();
      }
    });

    // Update wake lock when setting changes
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.keepScreenAwake != next.keepScreenAwake) {
        _updateWakeLock();
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onSelected: (value) async {
              if (value == 'session_history') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SessionHistoryScreen(),
                  ),
                );
              } else if (value == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              } else if (value == 'about') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              } else if (value == 'change_device') {
                await _navigateToDeviceSelection();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'change_device',
                child: Row(
                  children: [
                    Icon(Icons.bluetooth_searching),
                    SizedBox(width: 12),
                    Text('Change Device'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'session_history',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 12),
                    Text('Session History'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 12),
                    Text('About'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = _isLandscape(constraints);

              if (isLandscape) {
                return _buildLandscapeLayout(
                  theme: theme,
                  settings: settings,
                  heartRateAsync: heartRateAsync,
                  sessionState: sessionState,
                  isReconnecting: isReconnecting,
                  constraints: constraints,
                );
              } else {
                return _buildPortraitLayout(
                  theme: theme,
                  settings: settings,
                  heartRateAsync: heartRateAsync,
                  sessionState: sessionState,
                  isReconnecting: isReconnecting,
                  constraints: constraints,
                );
              }
            },
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

  /// Builds the portrait (vertical stacking) layout.
  Widget _buildPortraitLayout({
    required ThemeData theme,
    required dynamic settings,
    required AsyncValue heartRateAsync,
    required dynamic sessionState,
    required bool isReconnecting,
    required BoxConstraints constraints,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Large BPM Display - highest priority, flex: 3
          Flexible(
            flex: 3,
            child: Center(
              child: _buildBpmDisplay(
                theme: theme,
                heartRateAsync: heartRateAsync,
                isReconnecting: isReconnecting,
                isPaused: sessionState.isPaused,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Heart Rate Chart - flex: 2, with minimum height
          Flexible(
            flex: 2,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minChartHeight),
              child: _buildChart(
                theme: theme,
                settings: settings,
                heartRateAsync: heartRateAsync,
                sessionState: sessionState,
                isReconnecting: isReconnecting,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Session Statistics - flex: 2, adaptive display
          Flexible(
            flex: 2,
            child: LayoutBuilder(
              builder: (context, statsConstraints) {
                return _buildStatisticsSection(
                  theme: theme,
                  sessionState: sessionState,
                  availableHeight: statsConstraints.maxHeight,
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Session Control Buttons - fixed height
          _buildButtonRow(theme: theme, sessionState: sessionState),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Builds the landscape (side-by-side) layout.
  Widget _buildLandscapeLayout({
    required ThemeData theme,
    required dynamic settings,
    required AsyncValue heartRateAsync,
    required dynamic sessionState,
    required bool isReconnecting,
    required BoxConstraints constraints,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left column: BPM display + Chart
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // BPM Display
                Flexible(
                  flex: 2,
                  child: Center(
                    child: _buildBpmDisplay(
                      theme: theme,
                      heartRateAsync: heartRateAsync,
                      isReconnecting: isReconnecting,
                      isPaused: sessionState.isPaused,
                      isLandscape: true,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Chart
                Flexible(
                  flex: 2,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: _minChartHeight,
                    ),
                    child: _buildChart(
                      theme: theme,
                      settings: settings,
                      heartRateAsync: heartRateAsync,
                      sessionState: sessionState,
                      isReconnecting: isReconnecting,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right column: Statistics + Buttons
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Statistics section
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, statsConstraints) {
                      return _buildStatisticsSection(
                        theme: theme,
                        sessionState: sessionState,
                        availableHeight: statsConstraints.maxHeight,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Buttons at bottom
                _buildButtonRow(theme: theme, sessionState: sessionState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the heart rate chart widget.
  Widget _buildChart({
    required ThemeData theme,
    required dynamic settings,
    required AsyncValue heartRateAsync,
    required dynamic sessionState,
    required bool isReconnecting,
  }) {
    return heartRateAsync.when(
      data: (hrData) {
        final color = HeartRateZoneCalculator.getColorForZone(hrData.zone);
        return HeartRateChart(
          readings: _recentReadings,
          windowSeconds: settings.chartWindowSeconds,
          lineColor: isReconnecting || sessionState.isPaused
              ? color.withValues(alpha: 0.5)
              : color,
          referenceTime: sessionState.isPaused ? _pausedAt : null,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Chart unavailable',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  /// Builds the statistics section with adaptive display.
  Widget _buildStatisticsSection({
    required ThemeData theme,
    required dynamic sessionState,
    required double availableHeight,
  }) {
    final duration = _formatDuration(sessionState.duration);
    final avgHr = sessionState.avgHr != null ? '${sessionState.avgHr}' : '--';
    final minHr = sessionState.minHr != null ? '${sessionState.minHr}' : '--';
    final maxHr = sessionState.maxHr != null ? '${sessionState.maxHr}' : '--';

    // Use compact display when space is constrained
    if (availableHeight < _statsHeightThreshold) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Session Statistics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          CompactStatsRow(
            duration: duration,
            avgHr: avgHr,
            minHr: minHr,
            maxHr: maxHr,
          ),
        ],
      );
    }

    // Use grid display when space allows
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session Statistics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.8,
            children: [
              SessionStatsCard(
                icon: Icons.timer,
                label: 'Duration',
                value: duration,
              ),
              SessionStatsCard(
                icon: Icons.favorite,
                label: 'Average',
                value: avgHr,
              ),
              SessionStatsCard(
                icon: Icons.arrow_downward,
                label: 'Minimum',
                value: minHr,
                iconColor: Colors.blue,
              ),
              SessionStatsCard(
                icon: Icons.arrow_upward,
                label: 'Maximum',
                value: maxHr,
                iconColor: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the action buttons row with fixed compact height.
  Widget _buildButtonRow({
    required ThemeData theme,
    required dynamic sessionState,
  }) {
    return SizedBox(
      height: _buttonHeight,
      child: Row(
        children: [
          // Pause/Resume Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                final notifier = ref.read(sessionProvider.notifier);
                if (sessionState.isPaused) {
                  notifier.resumeSession();
                  setState(() {
                    _pausedAt = null;
                  });
                } else {
                  notifier.pauseSession();
                  setState(() {
                    _pausedAt = DateTime.now();
                  });
                }
              },
              icon: Icon(
                sessionState.isPaused ? Icons.play_arrow : Icons.pause,
                size: 18,
              ),
              label: Text(sessionState.isPaused ? 'Resume' : 'Pause'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                backgroundColor: sessionState.isPaused
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary,
                foregroundColor: sessionState.isPaused
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Restart Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                // Show confirmation dialog
                final shouldRestart = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Restart Session?'),
                    content: const Text(
                      'This will end the current session and start a new one. '
                      'Your current session data will be saved.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Restart'),
                      ),
                    ],
                  ),
                );

                if (shouldRestart == true) {
                  await ref
                      .read(sessionProvider.notifier)
                      .restartSession(widget.deviceName);
                  // Clear recent readings for the chart
                  if (mounted) {
                    setState(() {
                      _recentReadings = [];
                    });
                  }
                }
              },
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('Restart'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
              ),
            ),
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
    required bool isPaused,
    bool isLandscape = false,
  }) {
    // Determine font size range based on orientation
    final maxFontSize = isLandscape ? 100.0 : 120.0;
    const minFontSize = 72.0;

    // If paused, show the last known BPM with a paused indicator
    if (isPaused && _lastKnownBpm != null) {
      return _buildPausedBpmDisplay(
        theme: theme,
        maxFontSize: maxFontSize,
        minFontSize: minFontSize,
      );
    }

    // If reconnecting, show the last known BPM in a dimmed state
    if (isReconnecting && _lastKnownBpm != null) {
      return _buildReconnectingBpmDisplay(
        theme: theme,
        maxFontSize: maxFontSize,
        minFontSize: minFontSize,
      );
    }

    return heartRateAsync.when(
      data: (hrData) => _buildActiveBpmDisplay(
        theme: theme,
        hrData: hrData,
        maxFontSize: maxFontSize,
        minFontSize: minFontSize,
      ),
      loading: () => _buildLoadingBpmDisplay(
        theme: theme,
        maxFontSize: maxFontSize,
        minFontSize: minFontSize,
      ),
      error: (error, stack) => _buildErrorBpmDisplay(
        theme: theme,
        maxFontSize: maxFontSize,
        minFontSize: minFontSize,
      ),
    );
  }

  /// Builds the BPM display when paused.
  Widget _buildPausedBpmDisplay({
    required ThemeData theme,
    required double maxFontSize,
    required double minFontSize,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minFontSize,
                maxHeight: maxFontSize * 1.2,
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: 0.5,
                child: Text(
                  _lastKnownBpm.toString(),
                  style: TextStyle(
                    fontSize: maxFontSize,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'BPM',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pause, size: 16, color: theme.colorScheme.secondary),
              const SizedBox(width: 6),
              Text(
                'Paused',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the BPM display when reconnecting.
  Widget _buildReconnectingBpmDisplay({
    required ThemeData theme,
    required double maxFontSize,
    required double minFontSize,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minFontSize,
                maxHeight: maxFontSize * 1.2,
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: 0.3,
                child: Text(
                  _lastKnownBpm.toString(),
                  style: TextStyle(
                    fontSize: maxFontSize,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'BPM',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Reconnecting...',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the active BPM display with heart rate data.
  Widget _buildActiveBpmDisplay({
    required ThemeData theme,
    required HeartRateData hrData,
    required double maxFontSize,
    required double minFontSize,
  }) {
    final color = HeartRateZoneCalculator.getColorForZone(hrData.zone);
    final zoneLabel = HeartRateZoneCalculator.getZoneLabel(hrData.zone);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated BPM value with smooth number transitions
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minFontSize,
                maxHeight: maxFontSize * 1.2,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: AnimatedDefaultTextStyle(
                  key: ValueKey<int>(hrData.bpm),
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: maxFontSize,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  child: Text(hrData.bpm.toString()),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'BPM',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        // Animated zone label with smooth color transitions
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: theme.textTheme.titleSmall!.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            child: Text(zoneLabel),
          ),
        ),
      ],
    );
  }

  /// Builds the loading state BPM display.
  Widget _buildLoadingBpmDisplay({
    required ThemeData theme,
    required double maxFontSize,
    required double minFontSize,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minFontSize,
                maxHeight: maxFontSize * 1.2,
              ),
              child: Text(
                '---',
                style: TextStyle(
                  fontSize: maxFontSize,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Waiting for data...',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  /// Builds the error state BPM display.
  Widget _buildErrorBpmDisplay({
    required ThemeData theme,
    required double maxFontSize,
    required double minFontSize,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minFontSize,
                maxHeight: maxFontSize * 1.2,
              ),
              child: Text(
                '---',
                style: TextStyle(
                  fontSize: maxFontSize,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Connection error',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ],
    );
  }
}
