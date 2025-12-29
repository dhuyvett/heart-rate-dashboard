import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/app_settings.dart';
import '../models/heart_rate_data.dart';
import '../models/heart_rate_reading.dart';
import '../models/session_statistic.dart';
import '../models/session_state.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/heart_rate_provider.dart';
import '../providers/reconnection_handler_provider.dart';
import '../providers/session_provider.dart';
import '../providers/settings_provider.dart';
import '../services/bluetooth_service.dart' as bt;
import '../services/database_service.dart';
import '../services/reconnection_handler.dart';
import '../utils/app_logger.dart';
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
/// - Landscape: Side-by-side layout with BPM+chart+buttons on left, stats on right
class HeartRateMonitoringScreen extends ConsumerStatefulWidget {
  /// The name of the connected device.
  final String deviceName;
  final String sessionName;
  final VoidCallback? onHeartRateUpdate;
  final VoidCallback? onChangeDevice;
  final bool enableSessionRestore;
  final bool loadRecentReadings;

  const HeartRateMonitoringScreen({
    required this.deviceName,
    required this.sessionName,
    this.onHeartRateUpdate,
    this.onChangeDevice,
    this.enableSessionRestore = true,
    this.loadRecentReadings = true,
    super.key,
  });

  @override
  ConsumerState<HeartRateMonitoringScreen> createState() =>
      _HeartRateMonitoringScreenState();
}

class _HeartRateMonitoringScreenState
    extends ConsumerState<HeartRateMonitoringScreen> {
  static final _logger = AppLogger.getLogger('HeartRateMonitoringScreen');
  List<HeartRateReading> _recentReadings = [];
  bool _sessionStarted = false;
  int? _lastKnownBpm;
  late final ReconnectionController _reconnectionHandler;
  ProviderSubscription<AsyncValue<HeartRateData>>? _heartRateListener;
  ProviderSubscription<AsyncValue<AppSettings>>? _settingsListener;
  StreamSubscription<ReconnectionState>? _reconnectionSubscription;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _speedDecayTimer;
  ReconnectionState _reconnectionState = ReconnectionState.idle();
  DateTime? _pausedAt;
  Position? _lastPosition;
  DateTime? _lastPositionTime;

  /// Threshold for switching between grid and compact statistics display.
  static const double _statsHeightThreshold = 200.0;

  /// Minimum height for the chart widget.
  static const double _minChartHeight = 100.0;

  /// Fixed height for action buttons.
  static const double _buttonHeight = 44.0;

  @override
  void initState() {
    super.initState();
    _reconnectionHandler = ref.read(reconnectionHandlerProvider);
    _listenToHeartRate();
    _listenToSettings();
    _startSession();
    _setupReconnectionListener();
    _updateWakeLock();
    _startGpsTracking();
    _startSpeedDecayTimer();
  }

  @override
  void dispose() {
    _reconnectionSubscription?.cancel();
    _heartRateListener?.close();
    _settingsListener?.close();
    _positionSubscription?.cancel();
    _speedDecayTimer?.cancel();
    _reconnectionHandler.stopMonitoring();
    // Always disable wake lock when leaving the screen
    WakelockPlus.disable();
    super.dispose();
  }

  /// Updates the wake lock based on the current setting.
  void _updateWakeLock() {
    final settings = ref.read(settingsProvider).asData?.value;
    if (settings?.keepScreenAwake == true) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  /// Sets up the reconnection state listener.
  void _setupReconnectionListener() {
    _reconnectionSubscription = _reconnectionHandler.stateStream.listen((
      state,
    ) {
      if (mounted) {
        setState(() {
          _reconnectionState = state;
        });

        // If all attempts failed, show the failure dialog
        if (state.hasFailed) {
          _showReconnectionFailedDialog();
        }
      }
    });
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
        await _reconnectionHandler.retryReconnection();
      } else {
        // End session and go to device selection
        await _endSessionAndNavigateToDeviceSelection();
      }
    }
  }

  /// Ends the current session and navigates to device selection.
  Future<void> _endSessionAndNavigateToDeviceSelection({
    bool skipDatabase = false,
  }) async {
    _reconnectionHandler.stopMonitoring();
    final lastDeviceId = skipDatabase
        ? null
        : await DatabaseService.instance.getSetting('last_connected_device_id');
    widget.onChangeDevice?.call();
    await bt.BluetoothService.instance.disconnect();
    if (!skipDatabase && lastDeviceId != null && lastDeviceId.isNotEmpty) {
      await DatabaseService.instance.setSetting(
        'last_connected_device_id',
        lastDeviceId,
      );
    }
    await ref.read(sessionProvider.notifier).endSession();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DeviceSelectionScreen()),
        (route) => false,
      );
    }
  }

  /// Navigates to the device selection screen from the menu.
  Future<void> _navigateToDeviceSelection() async {
    // Disconnect from current device
    _reconnectionHandler.markManualDisconnect();
    widget.onChangeDevice?.call();
    await bt.BluetoothService.instance.disconnect();

    // Stop reconnection monitoring
    _reconnectionHandler.stopMonitoring();

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

  @visibleForTesting
  Future<void> triggerChangeDevice() => _navigateToDeviceSelection();

  @visibleForTesting
  Future<void> triggerStartSessionForTest() => _startSession();

  @visibleForTesting
  Future<void> triggerEndSessionForTest() =>
      _endSessionAndNavigateToDeviceSelection(skipDatabase: true);

  Future<void> _promptRenameSession() async {
    final sessionState = ref.read(sessionProvider);
    final controller = TextEditingController(
      text: sessionState.sessionName ?? widget.sessionName,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Session'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Session name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              Navigator.of(context).pop(trimmed.isEmpty ? null : trimmed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      try {
        await ref.read(sessionProvider.notifier).renameActiveSession(newName);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Session renamed')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error renaming session: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Starts a new workout session.
  Future<void> _startSession() async {
    if (!_sessionStarted) {
      _sessionStarted = true;
      try {
        await ref
            .read(sessionProvider.notifier)
            .startSession(
              deviceName: widget.deviceName,
              sessionName: widget.sessionName,
            );
      } catch (e) {
        _sessionStarted = false;
        _logger.e('Failed to start session', error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not start session: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      // Set up reconnection monitoring
      final bluetoothService = bt.BluetoothService.instance;
      if (!bluetoothService.isInDemoMode) {
        if (widget.enableSessionRestore) {
          // Start monitoring for reconnection (not needed for demo mode)
          final lastDeviceId = await DatabaseService.instance.getSetting(
            'last_connected_device_id',
          );
          if (lastDeviceId != null && lastDeviceId.isNotEmpty) {
            _reconnectionHandler.setSessionIdToResume(
              ref.read(sessionProvider).currentSessionId,
            );
            _reconnectionHandler.startMonitoring(lastDeviceId);
          }
        }
      }

      if (widget.loadRecentReadings) {
        _loadRecentReadings();
      }
    }
  }

  /// Loads recent readings from the database for the chart.
  Future<void> _loadRecentReadings() async {
    final sessionState = ref.read(sessionProvider);
    if (sessionState.currentSessionId == null) return;

    final settings = ref.read(settingsProvider).asData?.value;
    if (settings == null) return;
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

      if (!mounted) return;
      setState(() {
        _recentReadings = readings;
      });
    } catch (e, stackTrace) {
      // Log error but continue - chart will show available data
      _logger.w(
        'Error loading recent readings',
        error: e,
        stackTrace: stackTrace,
      );
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

  void _listenToHeartRate() {
    _heartRateListener = ref.listenManual<AsyncValue<HeartRateData>>(
      heartRateProvider,
      (previous, next) {
        final sessionState = ref.read(sessionProvider);
        if (next is AsyncData<HeartRateData>) {
          if (!sessionState.isPaused) {
            widget.onHeartRateUpdate?.call();
            _lastKnownBpm = next.value.bpm;
            _reconnectionHandler.setLastKnownBpm(next.value.bpm);
            if (widget.loadRecentReadings) {
              _loadRecentReadings();
            }
          }
        }
      },
    );
  }

  Future<void> _startGpsTracking() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      );

      _positionSubscription?.cancel();
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            _handlePosition,
            onError: (Object error, StackTrace stack) {
              _logger.w('GPS stream error', error: error, stackTrace: stack);
            },
          );
    } catch (e, stackTrace) {
      _logger.w(
        'Failed to start GPS tracking',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _handlePosition(Position position) {
    final sessionState = ref.read(sessionProvider);
    if (!sessionState.isActive || sessionState.isPaused) {
      _lastPosition = position;
      _lastPositionTime = position.timestamp;
      return;
    }

    final previous = _lastPosition;
    final previousTime = _lastPositionTime;
    final now = position.timestamp;

    double deltaDistance = 0;
    if (previous != null && previousTime != null) {
      deltaDistance = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );
    }

    double speed = position.speed.isFinite && position.speed > 0
        ? position.speed
        : 0;
    if (speed == 0 && previousTime != null && now.isAfter(previousTime)) {
      final seconds = now.difference(previousTime).inMilliseconds / 1000;
      if (seconds > 0) {
        speed = deltaDistance / seconds;
      }
    }

    // Treat very small movements as stationary to avoid jitter.
    if (deltaDistance < 0.5) {
      speed = 0;
    }

    _lastPosition = position;
    _lastPositionTime = now;

    ref
        .read(sessionProvider.notifier)
        .updateGpsData(deltaDistanceMeters: deltaDistance, speedMps: speed);
  }

  void _startSpeedDecayTimer() {
    _speedDecayTimer?.cancel();
    _speedDecayTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final lastTime = _lastPositionTime;
      final sessionState = ref.read(sessionProvider);
      if (!sessionState.isActive || sessionState.isPaused) return;
      if (lastTime == null) return;

      final idleSeconds = DateTime.now().difference(lastTime).inSeconds;
      if (idleSeconds >= 5 && (sessionState.speedMps ?? 0) > 0) {
        ref
            .read(sessionProvider.notifier)
            .updateGpsData(deltaDistanceMeters: 0, speedMps: 0);
      }
    });
  }

  List<_StatDisplay> _buildSelectedStats({
    required ThemeData theme,
    required AppSettings settings,
    required SessionState sessionState,
  }) {
    final duration = _formatDuration(sessionState.duration);
    final avgHr = sessionState.avgHr != null ? '${sessionState.avgHr}' : '--';
    final minHr = sessionState.minHr != null ? '${sessionState.minHr}' : '--';
    final maxHr = sessionState.maxHr != null ? '${sessionState.maxHr}' : '--';
    final speed = sessionState.speedMps != null
        ? _formatSpeed(sessionState.speedMps!, settings.useMiles)
        : '--';
    final distance = sessionState.distanceMeters != null
        ? _formatDistance(sessionState.distanceMeters!, settings.useMiles)
        : '--';

    return settings.visibleSessionStats.map((stat) {
      switch (stat) {
        case SessionStatistic.duration:
          return _StatDisplay(
            icon: Icons.timer,
            label: 'Duration',
            sublabel: 'Duration',
            value: duration,
            color: theme.colorScheme.primary,
          );
        case SessionStatistic.average:
          return _StatDisplay(
            icon: Icons.favorite,
            label: 'Average',
            sublabel: 'Avg',
            value: avgHr,
            color: theme.colorScheme.primary,
          );
        case SessionStatistic.minimum:
          return _StatDisplay(
            icon: Icons.arrow_downward,
            label: 'Minimum',
            sublabel: 'Min',
            value: minHr,
            color: Colors.blue,
          );
        case SessionStatistic.maximum:
          return _StatDisplay(
            icon: Icons.arrow_upward,
            label: 'Maximum',
            sublabel: 'Max',
            value: maxHr,
            color: Colors.red,
          );
        case SessionStatistic.speed:
          return _StatDisplay(
            icon: Icons.speed,
            label: 'Speed',
            sublabel: 'Speed',
            value: speed,
            color: Colors.orange,
          );
        case SessionStatistic.distance:
          return _StatDisplay(
            icon: Icons.route,
            label: 'Distance',
            sublabel: 'Distance',
            value: distance,
            color: Colors.teal,
          );
      }
    }).toList();
  }

  List<CompactStat> _toCompactStats(List<_StatDisplay> stats) {
    return stats
        .map(
          (stat) => CompactStat(
            icon: stat.icon,
            value: stat.value,
            sublabel: stat.sublabel,
            color: stat.color,
          ),
        )
        .toList();
  }

  String _formatSpeed(double speedMps, bool useMiles) {
    final value = useMiles ? speedMps * 2.23694 : speedMps * 3.6;
    final unit = useMiles ? 'mph' : 'km/h';
    return '${value.toStringAsFixed(1)} $unit';
  }

  String _formatDistance(double meters, bool useMiles) {
    final value = useMiles ? meters / 1609.34 : meters / 1000;
    final unit = useMiles ? 'mi' : 'km';
    final decimals = 1;
    return '${value.toStringAsFixed(decimals)} $unit';
  }

  Widget _buildEmptyStatsPlaceholder(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Session Statistics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              'No statistics selected. Update your preferences in Settings.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  void _listenToSettings() {
    _settingsListener = ref.listenManual<AsyncValue<AppSettings>>(
      settingsProvider,
      (previous, next) {
        final prevValue = previous?.asData?.value;
        final nextValue = next.asData?.value;
        if (prevValue?.keepScreenAwake != nextValue?.keepScreenAwake) {
          _updateWakeLock();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.asData?.value;
    final heartRateAsync = ref.watch(heartRateProvider);
    final sessionState = ref.watch(sessionProvider);
    final connectionAsync = ref.watch(bluetoothConnectionProvider);
    // Check if we're reconnecting
    final isReconnecting = _reconnectionState.isReconnecting;

    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
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
                );
              } else {
                return _buildPortraitLayout(
                  theme: theme,
                  settings: settings,
                  heartRateAsync: heartRateAsync,
                  sessionState: sessionState,
                  isReconnecting: isReconnecting,
                );
              }
            },
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  connectionAsync.when(
                    data: (connectionInfo) => ConnectionStatusIndicator(
                      connectionState: isReconnecting
                          ? bt.ConnectionState.reconnecting
                          : connectionInfo.connectionState,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (error, stack) => const SizedBox.shrink(),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.menu),
                    tooltip: 'Menu',
                    onSelected: (value) async {
                      if (value == 'rename_session') {
                        await _promptRenameSession();
                      } else if (value == 'session_history') {
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
                          MaterialPageRoute(
                            builder: (context) => const AboutScreen(),
                          ),
                        );
                      } else if (value == 'change_device') {
                        await _navigateToDeviceSelection();
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'rename_session',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 12),
                            Text('Rename Session'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'change_device',
                        key: ValueKey('change_device_menu_item'),
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

  /// Builds the portrait (vertical stacking) layout.
  Widget _buildPortraitLayout({
    required ThemeData theme,
    required AppSettings settings,
    required AsyncValue heartRateAsync,
    required SessionState sessionState,
    required bool isReconnecting,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        children: [
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

          const SizedBox(height: 12),

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

          const SizedBox(height: 12),

          // Session Statistics - flex: 2, adaptive display
          Flexible(
            flex: 2,
            child: LayoutBuilder(
              builder: (context, statsConstraints) {
                return _buildStatisticsSection(
                  theme: theme,
                  settings: settings,
                  sessionState: sessionState,
                  availableHeight: statsConstraints.maxHeight,
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Session Control Buttons - fixed height
          _buildButtonRow(theme: theme, sessionState: sessionState),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// Builds the landscape (side-by-side) layout.
  Widget _buildLandscapeLayout({
    required ThemeData theme,
    required AppSettings settings,
    required AsyncValue heartRateAsync,
    required SessionState sessionState,
    required bool isReconnecting,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left column: BPM display + Chart
          Expanded(
            flex: 1,
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

                const SizedBox(height: 8),

                // Buttons under the left column
                _buildButtonRow(theme: theme, sessionState: sessionState),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Right column: Statistics
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Statistics section
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, statsConstraints) {
                      return _buildStatisticsSection(
                        theme: theme,
                        settings: settings,
                        sessionState: sessionState,
                        availableHeight: statsConstraints.maxHeight,
                      );
                    },
                  ),
                ),
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
    required AppSettings settings,
    required AsyncValue heartRateAsync,
    required SessionState sessionState,
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
    required AppSettings settings,
    required SessionState sessionState,
    required double availableHeight,
  }) {
    final stats = _buildSelectedStats(
      theme: theme,
      settings: settings,
      sessionState: sessionState,
    );

    if (stats.isEmpty) {
      return _buildEmptyStatsPlaceholder(theme);
    }

    // Use compact display when space is constrained
    if (availableHeight < _statsHeightThreshold) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Session Statistics',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          CompactStatsRow(stats: _toCompactStats(stats)),
        ],
      );
    }

    // Use grid display when space allows
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session Statistics',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final columns = stats.length >= 5
                  ? 3
                  : math.max(1, math.min(2, stats.length));
              const spacing = 8.0;
              final totalSpacing = spacing * (columns - 1);
              final rows = (stats.length / columns).ceil();
              final totalRunSpacing = spacing * math.max(0, rows - 1);
              final itemWidth = ((box.maxWidth - totalSpacing) / columns)
                  .clamp(0, double.infinity)
                  .toDouble();
              final itemHeight = rows == 0
                  ? 0.0
                  : ((box.maxHeight - totalRunSpacing) / rows)
                        .clamp(0, double.infinity)
                        .toDouble();
              final scale = (itemHeight / 90.0).clamp(1.0, 1.8).toDouble();

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: stats
                    .map(
                      (stat) => SizedBox(
                        width: itemWidth,
                        height: itemHeight,
                        child: SessionStatsCard(
                          icon: stat.icon,
                          label: stat.label,
                          value: stat.value,
                          iconColor: stat.color,
                          scale: scale,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds the action buttons row with fixed compact height.
  Widget _buildButtonRow({
    required ThemeData theme,
    required SessionState sessionState,
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
          // End Session Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final shouldEnd = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('End Session?'),
                    content: const Text(
                      'This will stop recording and return to device selection.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('End Session'),
                      ),
                    ],
                  ),
                );

                if (shouldEnd == true) {
                  await _endSessionAndNavigateToDeviceSelection();
                }
              },
              icon: const Icon(Icons.stop, size: 18),
              label: const Text('End Session'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.colorScheme.onSurface,
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
                    fontFamily: 'SourceSans3',
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
                    fontFamily: 'SourceSans3',
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
                    fontFamily: 'SourceSans3',
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
                  fontFamily: 'SourceSans3',
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
                  fontFamily: 'SourceSans3',
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

class _StatDisplay {
  final IconData icon;
  final String label;
  final String? sublabel;
  final String value;
  final Color color;

  const _StatDisplay({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.sublabel,
  });
}
