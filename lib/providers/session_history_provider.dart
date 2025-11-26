import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_session.dart';
import '../services/database_service.dart';
import '../utils/app_logger.dart';

/// Notifier for managing session history state.
///
/// This notifier loads all completed workout sessions from the database
/// and provides methods for deleting individual or all sessions.
class SessionHistoryNotifier extends Notifier<List<WorkoutSession>> {
  static final _logger = AppLogger.getLogger('SessionHistoryNotifier');
  DatabaseService get _databaseService => DatabaseService.instance;

  @override
  List<WorkoutSession> build() {
    // Load sessions asynchronously
    loadSessions();
    // Return empty list initially
    return [];
  }

  /// Loads all completed sessions from the database.
  ///
  /// Sessions are automatically sorted by start time descending (newest first)
  /// in the database query.
  Future<void> loadSessions() async {
    try {
      final sessions = await _databaseService.getAllCompletedSessions();
      state = sessions;
    } catch (e, stackTrace) {
      // Log error for debugging
      _logger.e('Error loading sessions', error: e, stackTrace: stackTrace);
      // Keep current state on error
    }
  }

  /// Deletes a specific session and all its associated heart rate readings.
  ///
  /// Updates the state to remove the deleted session from the list.
  Future<void> deleteSession(int sessionId) async {
    try {
      await _databaseService.deleteSession(sessionId);
      // Remove session from state
      state = state.where((session) => session.id != sessionId).toList();
    } catch (e, stackTrace) {
      // Log error for debugging
      _logger.e('Error deleting session', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Deletes all sessions and all associated heart rate readings.
  ///
  /// Updates the state to an empty list.
  Future<void> deleteAllSessions() async {
    try {
      await _databaseService.deleteAllSessions();
      // Clear state
      state = [];
    } catch (e, stackTrace) {
      // Log error for debugging
      _logger.e(
        'Error deleting all sessions',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

/// Provider for session history state.
///
/// Manages the list of completed workout sessions and provides
/// methods for loading and deleting sessions.
final sessionHistoryProvider =
    NotifierProvider<SessionHistoryNotifier, List<WorkoutSession>>(() {
      return SessionHistoryNotifier();
    });
