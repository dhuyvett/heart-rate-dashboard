import 'dart:async';
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

  // Pause/resume tracking
  Duration _totalPausedDuration = Duration.zero;
  DateTime? _lastPauseTime;

  @override
  SessionState build() {
    // Return inactive state initially
    return SessionState.inactive();
  }

  /// Starts a new workout session.
  ///
  /// Creates a session in the database and begins listening to heart rate
  /// readings for automatic recording and statistics calculation.
  Future<void> startSession(String deviceName) async {
    try {
      // Create session in database
      final sessionId = await _databaseService.createSession(deviceName);
      final startTime = DateTime.now();

      // Initialize session state
      state = SessionState(
        currentSessionId: sessionId,
        startTime: startTime,
        duration: Duration.zero,
      );

      // Reset statistics accumulators
      _sumBpm = 0;

      // Reset pause tracking
      _totalPausedDuration = Duration.zero;
      _lastPauseTime = null;

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
    _lastPauseTime = DateTime.now();

    // Update state to paused (duration timer continues but won't update while paused)
    state = state.copyWith(isPaused: true);

    _logger.d('Session paused at $_lastPauseTime');
  }

  /// Resumes a paused session.
  ///
  /// Accumulates the paused time and continues recording heart rate readings.
  void resumeSession() {
    if (!state.isActive || !state.isPaused) return;

    // Add this pause period to total paused duration
    if (_lastPauseTime != null) {
      final pauseDuration = DateTime.now().difference(_lastPauseTime!);
      _totalPausedDuration += pauseDuration;
      _logger.d(
        'Session resumed. Pause duration: $pauseDuration, Total paused: $_totalPausedDuration',
      );
      _lastPauseTime = null;
    }

    // Update state to not paused (timer continues and will now update duration)
    state = state.copyWith(isPaused: false);
  }

  /// Restarts the session by ending the current one and starting a new one.
  ///
  /// Saves the current session's statistics and begins a fresh session
  /// with the same device.
  Future<void> restartSession(String deviceName) async {
    await endSession();
    await startSession(deviceName);
  }

  /// Ends the current session.
  ///
  /// Saves final statistics to the database and resets to inactive state.
  Future<void> endSession() async {
    if (!state.isActive || state.currentSessionId == null) return;

    try {
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
        );
      }

      // Reset to inactive state
      state = SessionState.inactive();
      _sumBpm = 0;

      // Reset pause tracking
      _totalPausedDuration = Duration.zero;
      _lastPauseTime = null;
    } catch (e, stackTrace) {
      // Log error for debugging
      _logger.e('Error ending session', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

/// Provider for workout session state.
///
/// Manages the current session, automatically records heart rate readings,
/// and calculates real-time statistics.
final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(() {
  return SessionNotifier();
});
