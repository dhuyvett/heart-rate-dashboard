import 'dart:async';
import 'dart:io';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/heart_rate_reading.dart';
import '../models/workout_session.dart';
import '../utils/app_logger.dart';
import '../utils/secure_key_manager.dart';

/// Service for managing the encrypted local database.
///
/// This service handles all database operations including session management,
/// heart rate reading storage, and settings persistence. The database is
/// encrypted using SQLCipher on mobile platforms with device-specific keys
/// stored in platform-native secure storage (Android Keystore, iOS Keychain).
///
/// Desktop platforms use unencrypted SQLite due to lack of SQLCipher support.
///
/// Uses singleton pattern to ensure only one database instance exists.
class DatabaseService {
  static final _logger = AppLogger.getLogger('DatabaseService');

  // Singleton instance
  static final DatabaseService instance = DatabaseService._internal();

  // Database instance
  Database? _database;

  // Completer to ensure only one initialization happens even with concurrent access
  Completer<Database>? _initializationCompleter;

  // Testing database factory (set by tests to use sqflite_common_ffi)
  DatabaseFactory? _testDatabaseFactory;

  // Database configuration
  static const String _databaseName = 'heart_rate_dashboard.db';
  static const int _databaseVersion = 2;

  // Table names
  static const String _tableHeartRateReadings = 'heart_rate_readings';
  static const String _tableWorkoutSessions = 'workout_sessions';
  static const String _tableAppSettings = 'app_settings';

  // Private constructor for singleton
  DatabaseService._internal();

  /// Gets the database instance, initializing it if necessary.
  ///
  /// Thread-safe: Multiple concurrent calls will wait for the same initialization
  /// to complete rather than triggering multiple initializations.
  Future<Database> get database async {
    // If already initialized, return immediately
    if (_database != null) return _database!;

    // If initialization is already in progress, wait for it
    if (_initializationCompleter != null) {
      _logger.d('Database initialization already in progress, waiting...');
      return await _initializationCompleter!.future;
    }

    // Start initialization
    _logger.d('Starting database initialization');
    _initializationCompleter = Completer<Database>();

    try {
      _database = await _initDatabase();
      _initializationCompleter!.complete(_database!);
      _logger.i('Database initialization completed successfully');
      return _database!;
    } catch (error) {
      _initializationCompleter!.completeError(error);
      _initializationCompleter = null; // Allow retry on next call
      rethrow;
    }
  }

  /// Checks if running on a desktop platform.
  bool get _isDesktop =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;

  /// Initializes the database with encryption.
  Future<Database> _initDatabase() async {
    // If test factory is set, use it for testing
    if (_testDatabaseFactory != null) {
      return await _testDatabaseFactory!.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    // Use FFI for desktop platforms (no encryption support)
    if (_isDesktop) {
      sqfliteFfiInit();
      final databaseFactory = databaseFactoryFfi;
      final appDir = await getApplicationDocumentsDirectory();
      final path = join(appDir.path, _databaseName);

      return await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    // Mobile platforms with encryption via SQLCipher
    final dbPath = await sqlcipher.getDatabasesPath();
    final path = join(dbPath, _databaseName);

    // Get or create device-specific encryption key from secure storage
    final encryptionKey = await SecureKeyManager.getOrCreateEncryptionKey();
    _logger.d('Using device-specific encryption key for database');

    return await sqlcipher.openDatabase(
      path,
      version: _databaseVersion,
      password: encryptionKey,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates the database schema on first initialization.
  Future<void> _onCreate(Database db, int version) async {
    // Create heart_rate_readings table
    await db.execute('''
      CREATE TABLE $_tableHeartRateReadings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        bpm INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES $_tableWorkoutSessions (id)
      )
    ''');

    // Create indexes on heart_rate_readings for fast querying
    await db.execute('''
      CREATE INDEX idx_hr_session_id
      ON $_tableHeartRateReadings (session_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_hr_timestamp
      ON $_tableHeartRateReadings (timestamp)
    ''');

    // Create workout_sessions table
    await db.execute('''
      CREATE TABLE $_tableWorkoutSessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        device_name TEXT NOT NULL,
        name TEXT NOT NULL,
        avg_hr INTEGER,
        min_hr INTEGER,
        max_hr INTEGER
      )
    ''');

    // Create index on workout_sessions for chronological ordering
    await db.execute('''
      CREATE INDEX idx_session_start_time
      ON $_tableWorkoutSessions (start_time)
    ''');

    // Create app_settings table
    await db.execute('''
      CREATE TABLE $_tableAppSettings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  /// Handles database schema upgrades for future versions.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $_tableWorkoutSessions ADD COLUMN name TEXT',
      );

      await db.execute('''
        UPDATE $_tableWorkoutSessions
        SET name = 'Session - ' || strftime('%Y-%m-%d %H:%M', start_time / 1000, 'unixepoch')
        WHERE name IS NULL
      ''');
    }
  }

  /// Creates a new workout session.
  ///
  /// [deviceName] is the name of the connected heart rate monitor.
  /// Returns the ID of the newly created session.
  Future<int> createSession({
    required String deviceName,
    required String name,
  }) async {
    final db = await database;
    final session = WorkoutSession(
      startTime: DateTime.now(),
      deviceName: deviceName,
      name: name,
    );

    return await db.insert(_tableWorkoutSessions, session.toMap());
  }

  /// Ends a workout session by setting the end time and statistics.
  ///
  /// [sessionId] is the ID of the session to end.
  /// [avgHr], [minHr], and [maxHr] are the calculated session statistics.
  Future<void> endSession({
    required int sessionId,
    required int avgHr,
    required int minHr,
    required int maxHr,
    DateTime? endTime,
  }) async {
    final db = await database;
    await db.update(
      _tableWorkoutSessions,
      {
        'end_time': (endTime ?? DateTime.now()).millisecondsSinceEpoch,
        'avg_hr': avgHr,
        'min_hr': minHr,
        'max_hr': maxHr,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Inserts a heart rate reading into the database.
  ///
  /// [sessionId] is the ID of the session this reading belongs to.
  /// [timestamp] is when the reading was captured.
  /// [bpm] is the heart rate in beats per minute.
  /// Returns the ID of the newly inserted reading.
  Future<int> insertHeartRateReading(
    int sessionId,
    DateTime timestamp,
    int bpm,
  ) async {
    final db = await database;
    final reading = HeartRateReading(
      sessionId: sessionId,
      timestamp: timestamp,
      bpm: bpm,
    );

    return await db.insert(_tableHeartRateReadings, reading.toMap());
  }

  /// Retrieves all heart rate readings for a specific session.
  ///
  /// [sessionId] is the ID of the session to query.
  /// Returns a list of readings ordered by timestamp.
  Future<List<HeartRateReading>> getReadingsBySession(int sessionId) async {
    final db = await database;
    final maps = await db.query(
      _tableHeartRateReadings,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) => HeartRateReading.fromMap(map)).toList();
  }

  /// Retrieves heart rate readings for a session within a time range.
  ///
  /// [sessionId] is the ID of the session to query.
  /// [startTime] and [endTime] define the time window.
  /// Returns a list of readings ordered by timestamp.
  Future<List<HeartRateReading>> getReadingsBySessionAndTimeRange(
    int sessionId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    final db = await database;
    final maps = await db.query(
      _tableHeartRateReadings,
      where: 'session_id = ? AND timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        sessionId,
        startTime.millisecondsSinceEpoch,
        endTime.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) => HeartRateReading.fromMap(map)).toList();
  }

  /// Gets the current active session (session without end_time).
  ///
  /// Returns the most recent session that hasn't been ended,
  /// or null if no active session exists.
  Future<WorkoutSession?> getCurrentSession() async {
    final db = await database;
    final maps = await db.query(
      _tableWorkoutSessions,
      where: 'end_time IS NULL',
      orderBy: 'start_time DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return WorkoutSession.fromMap(maps.first);
  }

  /// Checks if any session is currently active.
  Future<bool> hasActiveSession() async {
    final db = await database;
    final maps = await db.query(
      _tableWorkoutSessions,
      where: 'end_time IS NULL',
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  /// Gets a session by its ID.
  ///
  /// Returns the session or null if not found.
  Future<WorkoutSession?> getSessionById(int sessionId) async {
    final db = await database;
    final maps = await db.query(
      _tableWorkoutSessions,
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return WorkoutSession.fromMap(maps.first);
  }

  /// Retrieves all completed workout sessions.
  ///
  /// Returns a list of sessions that have been ended (end_time IS NOT NULL),
  /// sorted by start_time in descending order (newest first).
  Future<List<WorkoutSession>> getAllCompletedSessions() async {
    final db = await database;
    final maps = await db.query(
      _tableWorkoutSessions,
      where: 'end_time IS NOT NULL',
      orderBy: 'start_time DESC',
    );

    return maps.map((map) => WorkoutSession.fromMap(map)).toList();
  }

  /// Updates the name of a workout session.
  Future<void> updateSessionName({
    required int sessionId,
    required String name,
  }) async {
    final db = await database;
    await db.update(
      _tableWorkoutSessions,
      {'name': name},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Deletes a workout session and all its associated heart rate readings.
  ///
  /// Uses a transaction to ensure atomic deletion of both the session
  /// and all related heart rate readings.
  ///
  /// [sessionId] is the ID of the session to delete.
  Future<void> deleteSession(int sessionId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete all heart rate readings for this session
      await txn.delete(
        _tableHeartRateReadings,
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );

      // Delete the session
      await txn.delete(
        _tableWorkoutSessions,
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    });
  }

  /// Deletes all workout sessions and all heart rate readings.
  ///
  /// Uses a transaction to ensure atomic deletion of all data.
  /// This operation cannot be undone.
  Future<void> deleteAllSessions() async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete all heart rate readings
      await txn.delete(_tableHeartRateReadings);

      // Delete all sessions
      await txn.delete(_tableWorkoutSessions);
    });
  }

  /// Retrieves sessions older than the specified cutoff date.
  ///
  /// Returns sessions where end_time is before the cutoff date.
  /// Used for auto-deletion based on retention settings.
  ///
  /// [cutoffDate] is the date/time threshold - sessions ended before this
  /// will be returned.
  Future<List<WorkoutSession>> getSessionsOlderThan(DateTime cutoffDate) async {
    final db = await database;
    final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch;
    final maps = await db.query(
      _tableWorkoutSessions,
      where: 'end_time IS NOT NULL AND end_time < ?',
      whereArgs: [cutoffTimestamp],
      orderBy: 'start_time DESC',
    );

    return maps.map((map) => WorkoutSession.fromMap(map)).toList();
  }

  /// Retrieves the last reading timestamp for a session, if any.
  Future<DateTime?> getLastReadingTimestamp(int sessionId) async {
    final db = await database;
    final maps = await db.query(
      _tableHeartRateReadings,
      columns: ['timestamp'],
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return DateTime.fromMillisecondsSinceEpoch(maps.first['timestamp'] as int);
  }

  /// Completes any active session using recorded readings.
  ///
  /// If no readings exist, the active session is deleted (mirroring normal
  /// endSession behavior). Otherwise, statistics are recalculated from
  /// persisted readings and end time is set to the last reading timestamp.
  Future<void> completeActiveSessionWithLastReading() async {
    final activeSession = await getCurrentSession();
    if (activeSession == null || activeSession.id == null) return;

    final db = await database;
    final stats = await db.rawQuery(
      '''
      SELECT
        COUNT(*) as reading_count,
        AVG(bpm) as avg_hr,
        MIN(bpm) as min_hr,
        MAX(bpm) as max_hr,
        MAX(timestamp) as last_timestamp
      FROM $_tableHeartRateReadings
      WHERE session_id = ?
      ''',
      [activeSession.id],
    );

    final statRow = stats.isNotEmpty ? stats.first : <String, Object?>{};
    final readingsCount = (statRow['reading_count'] as num?)?.toInt() ?? 0;

    if (readingsCount == 0) {
      await deleteSession(activeSession.id!);
      return;
    }

    final avgHr = (statRow['avg_hr'] as num?)?.round();
    final minHr = (statRow['min_hr'] as num?)?.toInt();
    final maxHr = (statRow['max_hr'] as num?)?.toInt();
    final lastTimestamp =
        (statRow['last_timestamp'] as int?) ??
        activeSession.startTime.millisecondsSinceEpoch;

    if (avgHr == null || minHr == null || maxHr == null) return;

    await db.update(
      _tableWorkoutSessions,
      {
        'end_time': lastTimestamp,
        'avg_hr': avgHr,
        'min_hr': minHr,
        'max_hr': maxHr,
      },
      where: 'id = ?',
      whereArgs: [activeSession.id],
    );
  }

  /// Gets the previous session (older) relative to the current session.
  ///
  /// Returns the session with the most recent start_time that is still
  /// less than the current session's start_time, or null if no such
  /// session exists.
  ///
  /// [currentSessionId] is the ID of the reference session.
  Future<WorkoutSession?> getPreviousSession(int currentSessionId) async {
    final db = await database;

    // First, get the current session's start time
    final currentSession = await getSessionById(currentSessionId);
    if (currentSession == null) return null;

    final currentStartTime = currentSession.startTime.millisecondsSinceEpoch;

    // Query for sessions with earlier start times
    final maps = await db.query(
      _tableWorkoutSessions,
      where: 'start_time < ?',
      whereArgs: [currentStartTime],
      orderBy: 'start_time DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return WorkoutSession.fromMap(maps.first);
  }

  /// Gets the next session (newer) relative to the current session.
  ///
  /// Returns the session with the earliest start_time that is still
  /// greater than the current session's start_time, or null if no such
  /// session exists.
  ///
  /// [currentSessionId] is the ID of the reference session.
  Future<WorkoutSession?> getNextSession(int currentSessionId) async {
    final db = await database;

    // First, get the current session's start time
    final currentSession = await getSessionById(currentSessionId);
    if (currentSession == null) return null;

    final currentStartTime = currentSession.startTime.millisecondsSinceEpoch;

    // Query for sessions with later start times
    final maps = await db.query(
      _tableWorkoutSessions,
      where: 'start_time > ?',
      whereArgs: [currentStartTime],
      orderBy: 'start_time ASC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return WorkoutSession.fromMap(maps.first);
  }

  /// Retrieves a setting value by key.
  ///
  /// Returns the setting value or null if not found.
  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      _tableAppSettings,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  /// Stores or updates a setting value.
  ///
  /// Uses REPLACE to insert or update the setting atomically.
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(_tableAppSettings, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Initializes a fresh in-memory database for testing.
  ///
  /// This method is used by tests to avoid affecting the production database.
  /// Tests must provide a DatabaseFactory (e.g., from sqflite_common_ffi).
  Future<void> initializeForTesting(DatabaseFactory factory) async {
    _testDatabaseFactory = factory;
    // Close any existing database connection
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    // Initialize the new test database
    _database = await _initDatabase();
  }

  /// Closes the database connection for testing cleanup.
  Future<void> closeForTesting() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _initializationCompleter = null;
    _testDatabaseFactory = null;
  }

  /// Closes the database connection.
  ///
  /// Should be called when the app is shutting down.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _initializationCompleter = null;
  }
}
