import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_state.dart';
import '../services/database_service.dart';
import 'heart_rate_provider.dart';

/// Notifier for managing workout session state.
///
/// This notifier automatically records heart rate readings to the database
/// and maintains real-time statistics for the active session.
class SessionNotifier extends Notifier<SessionState> {
  DatabaseService get _databaseService => DatabaseService.instance;

  // Subscription for heart rate stream
  ProviderSubscription? _heartRateSubscription;

  // Timer for updating session duration
  Timer? _durationTimer;

  // Accumulated values for statistics calculation
  int _sumBpm = 0;

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

      // Start duration timer (updates every second)
      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.startTime != null) {
          final duration = DateTime.now().difference(state.startTime!);
          state = state.copyWith(duration: duration);
        }
      });

      // Subscribe to heart rate stream
      _heartRateSubscription?.close();
      _heartRateSubscription = ref.listen(heartRateProvider, (previous, next) {
        next.whenData((hrData) {
          _handleHeartRateReading(hrData.bpm);
        });
      });
    } catch (e) {
      // Log error for debugging
      // ignore: avoid_print
      print('Error starting session: $e');
      rethrow;
    }
  }

  /// Handles a new heart rate reading.
  ///
  /// Inserts the reading into the database and updates session statistics.
  Future<void> _handleHeartRateReading(int bpm) async {
    if (!state.isActive || state.currentSessionId == null) return;

    try {
      // Insert reading into database
      await _databaseService.insertHeartRateReading(
        state.currentSessionId!,
        DateTime.now(),
        bpm,
      );

      // Update statistics
      _updateStatistics(bpm);
    } catch (e) {
      // Log error for debugging
      // ignore: avoid_print
      print('Error handling heart rate reading: $e');
    }
  }

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

      // Save session statistics to database
      if (state.avgHr != null && state.minHr != null && state.maxHr != null) {
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
    } catch (e) {
      // Log error for debugging
      // ignore: avoid_print
      print('Error ending session: $e');
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
