import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../models/heart_rate_data.dart';
import '../models/session_state.dart';
import '../services/database_service.dart';
import '../utils/app_logger.dart';
import 'heart_rate_provider.dart';

/// Notifier for managing workout session state.
///
/// This notifier automatically records heart rate readings to the database
/// and maintains real-time statistics for the active session.
class SessionNotifier extends Notifier<SessionState> {
  static final _logger = AppLogger.getLogger('SessionNotifier');
  DatabaseService get _databaseService => DatabaseService.instance;

  // Subscription for heart rate stream
  ProviderSubscription? _heartRateSubscription;

  // Timer for updating session duration
  Timer? _durationTimer;

  // Accumulated values for statistics calculation
  int _sumBpm = 0;
  double _distanceMeters = 0;
  double _currentSpeedMps = 0;

  // Pause/resume tracking
  Duration _totalPausedDuration = Duration.zero;
  DateTime? _lastPauseTime;
  Future<void> _pauseIntervalWriteChain = Future.value();

  @override
  SessionState build() {
    // Return inactive state initially
    return SessionState.inactive();
  }

  /// Starts a new workout session.
  ///
  /// Creates a session in the database and begins listening to heart rate
  /// readings for automatic recording and statistics calculation.
  Future<void> startSession({
    required String deviceName,
    required String sessionName,
    required bool trackSpeedDistance,
  }) async {
    if (state.isActive) {
      _logger.w('Attempted to start a new session while one is active');
      throw StateError('A session is already active');
    }

    try {
      final hasActiveSession = await _databaseService.hasActiveSession();
      if (hasActiveSession) {
        _logger.w('Database reports an active session; blocking new start');
        throw StateError('Another session is still active');
      }

      // Create session in database
      final sessionId = await _databaseService.createSession(
        deviceName: deviceName,
        name: sessionName,
        trackSpeedDistance: trackSpeedDistance,
      );
      final startTime = DateTime.now();

      // Initialize session state
      state = SessionState(
        currentSessionId: sessionId,
        startTime: startTime,
        duration: Duration.zero,
        sessionName: sessionName,
        distanceMeters: 0,
        speedMps: 0,
      );

      // Reset statistics accumulators
      _sumBpm = 0;
      _distanceMeters = 0;
      _currentSpeedMps = 0;

      // Reset pause tracking
      _totalPausedDuration = Duration.zero;
      _lastPauseTime = null;
      _pauseIntervalWriteChain = Future.value();

      // Start duration timer (updates every second)
      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.startTime != null && !state.isPaused) {
          // Calculate active duration: elapsed time minus paused time
          final elapsed = DateTime.now().difference(state.startTime!);
          final activeDuration = elapsed - _totalPausedDuration;
          state = state.copyWith(duration: activeDuration);
        }
      });

      // Subscribe to heart rate stream
      _heartRateSubscription?.close();
      _heartRateSubscription = ref.listen(heartRateProvider, (previous, next) {
        if (next is AsyncData<HeartRateData>) {
          _handleHeartRateReading(next.value.bpm);
        }
      });
    } catch (e, stackTrace) {
      // Log error for debugging
      _logger.e('Error starting session', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Handles a new heart rate reading.
  ///
  /// Inserts the reading into the database and updates session statistics.
  /// Does nothing if the session is paused.
  Future<void> _handleHeartRateReading(int bpm) async {
    if (!state.isActive || state.currentSessionId == null || state.isPaused) {
      return;
    }

    try {
      // Insert reading into database
      await _databaseService.insertHeartRateReading(
        state.currentSessionId!,
        DateTime.now(),
        bpm,
      );

      // Update statistics
      _updateStatistics(bpm);
    } catch (e, stackTrace) {
      // Log error for debugging
      _logger.w(
        'Error handling heart rate reading',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @visibleForTesting
  Future<void> handleReadingForTest(int bpm) => _handleHeartRateReading(bpm);

  /// Updates session statistics with a new reading.
  void _updateStatistics(int bpm) {
    final newReadingsCount = state.readingsCount + 1;
    _sumBpm += bpm;

    final newAvgHr = (_sumBpm / newReadingsCount).round();
    final newMinHr = state.minHr == null
        ? bpm
        : (bpm < state.minHr! ? bpm : state.minHr!);
    final newMaxHr = state.maxHr == null
        ? bpm
        : (bpm > state.maxHr! ? bpm : state.maxHr!);

    state = state.copyWith(
      avgHr: newAvgHr,
      minHr: newMinHr,
      maxHr: newMaxHr,
      readingsCount: newReadingsCount,
    );
  }

  /// Pauses the current session.
  ///
  /// Stops recording heart rate readings and pauses the duration timer.
  /// The session can be resumed with [resumeSession].
  void pauseSession() {
    if (!state.isActive || state.isPaused) return;

    // Record when pause started
    final pauseStartedAt = DateTime.now();
    _lastPauseTime = pauseStartedAt;

    // Update state to paused (duration timer continues but won't update while paused)
    state = state.copyWith(isPaused: true);

    final sessionId = state.currentSessionId;
    if (sessionId != null) {
      _enqueuePauseIntervalWrite(() async {
        await _databaseService.startPauseInterval(
          sessionId: sessionId,
          pauseStart: pauseStartedAt,
        );
      }, operation: 'pause start').catchError((error, stackTrace) {
        _logger.w(
          'Error recording pause start',
          error: error,
          stackTrace: stackTrace,
        );
      });
    }

    _logger.d('Session paused at $_lastPauseTime');
  }

  /// Resumes a paused session.
  ///
  /// Accumulates the paused time and continues recording heart rate readings.
  void resumeSession() {
    if (!state.isActive || !state.isPaused) return;
    final resumedAt = DateTime.now();

    // Add this pause period to total paused duration
    if (_lastPauseTime != null) {
      final pauseDuration = resumedAt.difference(_lastPauseTime!);
      _totalPausedDuration += pauseDuration;
      _logger.d(
        'Session resumed. Pause duration: $pauseDuration, Total paused: $_totalPausedDuration',
      );
      _lastPauseTime = null;
    }

    final sessionId = state.currentSessionId;
    if (sessionId != null) {
      _enqueuePauseIntervalWrite(() async {
        await _databaseService.endLatestPauseInterval(
          sessionId: sessionId,
          pauseEnd: resumedAt,
        );
      }, operation: 'pause end').catchError((error, stackTrace) {
        _logger.w(
          'Error recording pause end',
          error: error,
          stackTrace: stackTrace,
        );
      });
    }

    // Update state to not paused (timer continues and will now update duration)
    state = state.copyWith(isPaused: false);
  }

  /// Updates session speed and distance from a GPS sample.
  void updateGpsData({
    required double deltaDistanceMeters,
    required double speedMps,
    DateTime? timestamp,
    double? altitudeMeters,
  }) {
    if (!state.isActive) return;
    if (deltaDistanceMeters.isNaN || speedMps.isNaN) return;

    _distanceMeters += math.max(0, deltaDistanceMeters);
    _currentSpeedMps = math.max(0, speedMps);

    state = state.copyWith(
      distanceMeters: _distanceMeters,
      speedMps: _currentSpeedMps,
    );

    final sessionId = state.currentSessionId;
    if (sessionId != null && timestamp != null) {
      _databaseService
          .insertGpsSample(
            sessionId: sessionId,
            timestamp: timestamp,
            speedMps: _currentSpeedMps,
            altitudeMeters: altitudeMeters,
          )
          .catchError((e, stackTrace) {
            _logger.w(
              'Error saving GPS sample',
              error: e,
              stackTrace: stackTrace,
            );
            return 0;
          });
    }
  }

  /// Ends the current session.
  ///
  /// Saves final statistics to the database and resets to inactive state.
  Future<void> endSession() async {
    if (!state.isActive || state.currentSessionId == null) return;

    try {
      final endedAt = DateTime.now();

      // Ensure pause interval writes are fully flushed before ending session.
      await _pauseIntervalWriteChain;

      if (state.isPaused && _lastPauseTime != null) {
        _totalPausedDuration += endedAt.difference(_lastPauseTime!);
        _lastPauseTime = null;
      }

      // Stop timers and subscriptions
      _durationTimer?.cancel();
      _durationTimer = null;
      _heartRateSubscription?.close();
      _heartRateSubscription = null;

      // Save session statistics to database or delete empty session
      if (state.readingsCount == 0) {
        _logger.i('Deleting empty session with zero readings');
        await _databaseService.deleteSession(state.currentSessionId!);
      } else if (state.avgHr != null &&
          state.minHr != null &&
          state.maxHr != null) {
        await _databaseService.endSession(
          sessionId: state.currentSessionId!,
          avgHr: state.avgHr!,
          minHr: state.minHr!,
          maxHr: state.maxHr!,
          distanceMeters: state.distanceMeters,
          endTime: endedAt,
        );
      }

      // Reset to inactive state
      state = SessionState.inactive();
      _sumBpm = 0;
      _distanceMeters = 0;
      _currentSpeedMps = 0;

      // Reset pause tracking
      _totalPausedDuration = Duration.zero;
      _lastPauseTime = null;
      _pauseIntervalWriteChain = Future.value();
    } catch (e, stackTrace) {
      // Log error for debugging
      _logger.e('Error ending session', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Renames the active session and persists the change.
  Future<void> renameActiveSession(String name) async {
    if (!state.isActive || state.currentSessionId == null) return;
    try {
      await _databaseService.updateSessionName(
        sessionId: state.currentSessionId!,
        name: name,
      );
      state = state.copyWith(sessionName: name);
    } catch (e, stackTrace) {
      _logger.e(
        'Error renaming active session',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _enqueuePauseIntervalWrite(
    Future<void> Function() action, {
    required String operation,
  }) {
    _pauseIntervalWriteChain = _pauseIntervalWriteChain
        .catchError((_) {
          // Keep chain alive if an earlier write failed.
        })
        .then((_) => action())
        .catchError((error, stackTrace) {
          _logger.w(
            'Pause interval write failed ($operation)',
            error: error,
            stackTrace: stackTrace,
          );
        });

    return _pauseIntervalWriteChain;
  }
}

/// Provider for workout session state.
///
/// Manages the current session, automatically records heart rate readings,
/// and calculates real-time statistics.
final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(() {
  return SessionNotifier();
});
