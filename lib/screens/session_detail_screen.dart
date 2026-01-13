import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import 'package:intl/intl.dart';
import '../models/heart_rate_reading.dart';
import '../models/heart_rate_zone.dart';
import '../models/workout_session.dart';
import '../providers/session_history_provider.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../utils/heart_rate_zone_calculator.dart';
import '../widgets/heart_rate_chart.dart';
import '../widgets/session_stats_card.dart';
import '../widgets/zone_time_bar_chart.dart';

/// Session detail screen for viewing a specific workout session.
///
/// Displays the complete session heart rate graph spanning the entire
/// session duration, along with session statistics. Resembles the
/// HeartRateMonitoringScreen layout but without live BPM display.
///
/// Features:
/// - Complete heart rate graph for the session
/// - Session statistics (duration, average, min, max HR)
/// - Navigation to previous/next sessions
/// - Delete session functionality
/// - Responsive layout (portrait and landscape)
class SessionDetailScreen extends ConsumerStatefulWidget {
  final WorkoutSession session;

  const SessionDetailScreen({required this.session, super.key});

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  List<HeartRateReading> _readings = [];
  bool _isLoading = true;
  String? _errorMessage;
  late WorkoutSession _currentSession;
  bool _hasPreviousSession = false;
  bool _hasNextSession = false;

  /// Fixed heights for chart widgets.
  static const double _chartHeight = 220.0;
  static const double _zoneChartHeight = 160.0;
  static const double _statsCardMinWidth = 160.0;
  static const double _statsCardHeight = 96.0;

  /// Date formatter for displaying session date/time.
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy h:mm a');

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    _loadSessionData();
  }

  /// Loads heart rate readings and navigation state for the session.
  Future<void> _loadSessionData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load heart rate readings
      final readings = await DatabaseService.instance.getReadingsBySession(
        _currentSession.id!,
      );

      // Check for previous and next sessions
      final previousSession = await DatabaseService.instance.getPreviousSession(
        _currentSession.id!,
      );
      final nextSession = await DatabaseService.instance.getNextSession(
        _currentSession.id!,
      );

      if (mounted) {
        setState(() {
          _readings = readings;
          _hasPreviousSession = previousSession != null;
          _hasNextSession = nextSession != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading session data: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Navigates to the previous session.
  Future<void> _navigateToPreviousSession() async {
    try {
      final previousSession = await DatabaseService.instance.getPreviousSession(
        _currentSession.id!,
      );

      if (previousSession != null && mounted) {
        setState(() {
          _currentSession = previousSession;
        });
        await _loadSessionData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading previous session: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Navigates to the next session.
  Future<void> _navigateToNextSession() async {
    try {
      final nextSession = await DatabaseService.instance.getNextSession(
        _currentSession.id!,
      );

      if (nextSession != null && mounted) {
        setState(() {
          _currentSession = nextSession;
        });
        await _loadSessionData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading next session: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _renameSession() async {
    final controller = TextEditingController(text: _currentSession.name);
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

    if (newName != null) {
      try {
        await DatabaseService.instance.updateSessionName(
          sessionId: _currentSession.id!,
          name: newName,
        );
        setState(() {
          _currentSession = _currentSession.copyWith(name: newName);
        });
        // Refresh session history to reflect the rename
        if (mounted) {
          ref.read(sessionHistoryProvider.notifier).loadSessions();
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

  /// Shows confirmation dialog and deletes the session.
  Future<void> _deleteSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text(
          'Delete this session? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await DatabaseService.instance.deleteSession(_currentSession.id!);

        if (mounted) {
          // Refresh the session history list
          ref.read(sessionHistoryProvider.notifier).loadSessions();

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Session deleted')));
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting session: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
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
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load settings. Please retry.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(settingsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (settings) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_currentSession.deviceName),
            actions: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _hasPreviousSession
                    ? _navigateToPreviousSession
                    : null,
                tooltip: 'Previous session',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _hasNextSession ? _navigateToNextSession : null,
                tooltip: 'Next session',
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _renameSession,
                tooltip: 'Rename session',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteSession,
                tooltip: 'Delete session',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _buildScrollableLayout(theme: theme, settings: settings),
        );
      },
    );
  }

  /// Builds a single scrollable layout for all screen sizes.
  Widget _buildScrollableLayout({
    required ThemeData theme,
    required AppSettings settings,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSessionHeader(theme),
              const SizedBox(height: 16),
              SizedBox(
                height: _chartHeight,
                child: _buildChart(theme: theme, settings: settings),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: _zoneChartHeight,
                child: _buildZoneTimeChart(theme: theme, settings: settings),
              ),
              const SizedBox(height: 16),
              _buildStatisticsSection(
                theme: theme,
                settings: settings,
                availableWidth: (constraints.maxWidth - 32).clamp(
                  0,
                  double.infinity,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the session header with date/time information.
  Widget _buildSessionHeader(ThemeData theme) {
    final dateTimeStr = _dateFormat.format(_currentSession.startTime);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  dateTimeStr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _currentSession.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the heart rate chart widget.
  Widget _buildChart({
    required ThemeData theme,
    required AppSettings settings,
  }) {
    // Handle case where session has no readings
    if (_readings.isEmpty) {
      return Center(
        child: Text(
          'No heart rate data recorded for this session',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Calculate session duration in seconds for chart window
    final sessionDuration = _currentSession.getDuration();
    final windowSeconds = sessionDuration.inSeconds;

    // Determine chart color based on average heart rate
    final avgHr = _currentSession.avgHr ?? 0;
    final zone = HeartRateZoneCalculator.getZoneForBpm(avgHr, settings);
    final color = HeartRateZoneCalculator.getColorForZone(zone);

    return HeartRateChart(
      readings: _readings,
      windowSeconds: windowSeconds > 0 ? windowSeconds : 60,
      lineColor: color,
      zoneColorResolver: (reading) {
        final readingZone = HeartRateZoneCalculator.getZoneForBpm(
          reading.bpm,
          settings,
        );
        return HeartRateZoneCalculator.getColorForZone(readingZone);
      },
      referenceTime: _currentSession.endTime,
      isLiveMode: false,
    );
  }

  /// Builds the statistics section with adaptive display.
  Widget _buildStatisticsSection({
    required ThemeData theme,
    required AppSettings settings,
    required double availableWidth,
  }) {
    final duration = _formatDuration(_currentSession.getDuration());
    final avgHr = _currentSession.avgHr != null
        ? '${_currentSession.avgHr}'
        : 'N/A';
    final minHr = _currentSession.minHr != null
        ? '${_currentSession.minHr}'
        : 'N/A';
    final maxHr = _currentSession.maxHr != null
        ? '${_currentSession.maxHr}'
        : 'N/A';
    final distance = _currentSession.distanceMeters != null
        ? _formatDistance(_currentSession.distanceMeters!, settings.useMiles)
        : 'N/A';
    final avgSpeed = _currentSession.distanceMeters != null
        ? _formatAverageSpeed(
            _currentSession.distanceMeters!,
            _currentSession.getDuration(),
            settings.useMiles,
          )
        : 'N/A';

    final availableGridWidth = availableWidth.isFinite ? availableWidth : 0.0;
    final columns = _calculateStatsColumns(availableGridWidth);

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
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: _statsCardHeight,
          ),
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
            SessionStatsCard(
              icon: Icons.route,
              label: 'Distance',
              value: distance,
              iconColor: Colors.teal,
            ),
            SessionStatsCard(
              icon: Icons.speed,
              label: 'Avg Speed',
              value: avgSpeed,
              iconColor: Colors.indigo,
            ),
          ],
        ),
      ],
    );
  }

  String _formatDistance(double meters, bool useMiles) {
    final value = useMiles ? meters / 1609.34 : meters / 1000;
    final unit = useMiles ? 'mi' : 'km';
    return '${value.toStringAsFixed(1)} $unit';
  }

  String _formatAverageSpeed(
    double distanceMeters,
    Duration duration,
    bool useMiles,
  ) {
    final seconds = duration.inMilliseconds / 1000;
    if (seconds <= 0) {
      return 'N/A';
    }
    final speedMps = distanceMeters / seconds;
    return _formatSpeed(speedMps, useMiles);
  }

  String _formatSpeed(double speedMps, bool useMiles) {
    final value = useMiles ? speedMps * 2.23694 : speedMps * 3.6;
    final unit = useMiles ? 'mph' : 'km/h';
    return '${value.toStringAsFixed(1)} $unit';
  }

  int _calculateStatsColumns(double availableWidth) {
    if (availableWidth <= 0) {
      return 1;
    }
    final columns = (availableWidth / (_statsCardMinWidth + 8)).floor();
    return columns.clamp(1, 4);
  }

  Widget _buildZoneTimeChart({
    required ThemeData theme,
    required AppSettings settings,
  }) {
    if (_readings.isEmpty) {
      return Center(
        child: Text(
          'No zone data available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return ZoneTimeBarChart(
      zoneDurations: _calculateZoneDurations(settings),
      zoneRanges: HeartRateZoneCalculator.getZoneRanges(settings),
    );
  }

  Map<HeartRateZone, Duration> _calculateZoneDurations(AppSettings settings) {
    final durations = {
      for (final zone in HeartRateZone.values) zone: Duration.zero,
    };

    if (_readings.isEmpty) {
      return durations;
    }

    final sortedReadings = [..._readings]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final sessionStart = _currentSession.startTime;
    if (sessionStart.isBefore(sortedReadings.first.timestamp)) {
      final initialGap = sortedReadings.first.timestamp.difference(
        sessionStart,
      );
      if (!initialGap.isNegative && initialGap.inMilliseconds > 0) {
        final zone = HeartRateZoneCalculator.getZoneForBpm(
          sortedReadings.first.bpm,
          settings,
        );
        durations[zone] = durations[zone]! + initialGap;
      }
    }

    for (var i = 0; i < sortedReadings.length - 1; i++) {
      final current = sortedReadings[i];
      final next = sortedReadings[i + 1];
      final delta = next.timestamp.difference(current.timestamp);
      if (delta.isNegative || delta.inMilliseconds == 0) {
        continue;
      }
      final zone = HeartRateZoneCalculator.getZoneForBpm(current.bpm, settings);
      durations[zone] = durations[zone]! + delta;
    }

    final sessionEnd = _currentSession.endTime ?? sortedReadings.last.timestamp;
    final tailGap = sessionEnd.difference(sortedReadings.last.timestamp);
    if (!tailGap.isNegative && tailGap.inMilliseconds > 0) {
      final zone = HeartRateZoneCalculator.getZoneForBpm(
        sortedReadings.last.bpm,
        settings,
      );
      durations[zone] = durations[zone]! + tailGap;
    }

    return durations;
  }
}
