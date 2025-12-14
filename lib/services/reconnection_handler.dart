import 'dart:async';
import 'package:meta/meta.dart';
import '../utils/constants.dart';
import 'bluetooth_service.dart';

/// Public interface for reconnection handling to allow injection in tests.
abstract class ReconnectionController {
  ReconnectionState get state;
  Stream<ReconnectionState> get stateStream;
  void setLastKnownBpm(int bpm);
  void setSessionIdToResume(int? sessionId);
  int? get sessionIdToResume;
  @visibleForTesting
  set bluetoothService(BluetoothService service);
  @visibleForTesting
  set delayCalculator(Duration Function(int attempt) calculator);
  void markManualDisconnect();
  void startMonitoring(String deviceId);
  void stopMonitoring();
  Future<void> retryReconnection();
  void reset();
  Future<void> dispose();
}

/// Represents the current state of a reconnection attempt.
class ReconnectionState {
  /// Whether reconnection is currently in progress.
  final bool isReconnecting;

  /// The current attempt number (1-based).
  final int currentAttempt;

  /// The maximum number of attempts that will be made.
  final int maxAttempts;

  /// The last known BPM value before disconnection.
  final int? lastKnownBpm;

  /// Whether all reconnection attempts have failed.
  final bool hasFailed;

  /// Error message if reconnection failed.
  final String? errorMessage;

  /// Creates a reconnection state instance.
  const ReconnectionState({
    this.isReconnecting = false,
    this.currentAttempt = 0,
    this.maxAttempts = maxReconnectionAttempts,
    this.lastKnownBpm,
    this.hasFailed = false,
    this.errorMessage,
  });

  /// Creates an idle state (not reconnecting).
  factory ReconnectionState.idle() {
    return const ReconnectionState();
  }

  /// Creates a reconnecting state with the given attempt number.
  factory ReconnectionState.reconnecting({
    required int attempt,
    int? lastKnownBpm,
  }) {
    return ReconnectionState(
      isReconnecting: true,
      currentAttempt: attempt,
      lastKnownBpm: lastKnownBpm,
    );
  }

  /// Creates a failed state after all attempts exhausted.
  factory ReconnectionState.failed({int? lastKnownBpm, String? errorMessage}) {
    return ReconnectionState(
      isReconnecting: false,
      currentAttempt: maxReconnectionAttempts,
      hasFailed: true,
      lastKnownBpm: lastKnownBpm,
      errorMessage:
          errorMessage ??
          'Could not reconnect to device after multiple attempts.',
    );
  }

  /// Creates a copy with updated fields.
  ReconnectionState copyWith({
    bool? isReconnecting,
    int? currentAttempt,
    int? maxAttempts,
    int? lastKnownBpm,
    bool? hasFailed,
    String? errorMessage,
  }) {
    return ReconnectionState(
      isReconnecting: isReconnecting ?? this.isReconnecting,
      currentAttempt: currentAttempt ?? this.currentAttempt,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      lastKnownBpm: lastKnownBpm ?? this.lastKnownBpm,
      hasFailed: hasFailed ?? this.hasFailed,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReconnectionState &&
        other.isReconnecting == isReconnecting &&
        other.currentAttempt == currentAttempt &&
        other.maxAttempts == maxAttempts &&
        other.lastKnownBpm == lastKnownBpm &&
        other.hasFailed == hasFailed &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
    isReconnecting,
    currentAttempt,
    maxAttempts,
    lastKnownBpm,
    hasFailed,
    errorMessage,
  );

  @override
  String toString() {
    return 'ReconnectionState(isReconnecting: $isReconnecting, '
        'currentAttempt: $currentAttempt, maxAttempts: $maxAttempts, '
        'lastKnownBpm: $lastKnownBpm, hasFailed: $hasFailed, '
        'errorMessage: $errorMessage)';
  }
}

/// Handler for automatic reconnection to Bluetooth devices.
///
/// This handler:
/// - Monitors connection state for unexpected disconnections
/// - Attempts reconnection with exponential backoff
/// - Reports progress through a state stream
/// - Allows manual retry after failure
///
/// Retry timing follows exponential backoff:
/// - Attempts 1-3: 2s, 4s, 8s delays
/// - Attempts 4+: 30s delays
/// - Maximum 10 attempts total
class ReconnectionHandler implements ReconnectionController {
  // Singleton instance
  static final ReconnectionHandler instance = ReconnectionHandler._internal();

  // Bluetooth service dependency (injectable for testing)
  BluetoothService _bluetoothService = BluetoothService.instance;

  // Stream controller for reconnection state
  final StreamController<ReconnectionState> _stateController =
      StreamController<ReconnectionState>.broadcast();

  // Current state
  ReconnectionState _state = ReconnectionState.idle();

  // Subscription to connection state changes
  StreamSubscription<ConnectionState>? _connectionSubscription;

  // Timer for delayed reconnection attempts
  Timer? _reconnectionTimer;

  // Device ID to reconnect to
  String? _targetDeviceId;

  // Session ID to resume (if any)
  int? _sessionIdToResume;

  // Last known BPM value
  int? _lastKnownBpm;

  // Flag to track if this was a manual disconnect
  bool _wasManualDisconnect = false;

  // Flag to prevent concurrent reconnection attempts
  bool _isReconnecting = false;

  // Delay calculator (overridable for faster tests)
  Duration Function(int attempt) _delayCalculator = _defaultDelayForAttempt;

  // Private constructor for singleton
  ReconnectionHandler._internal();

  /// Gets the current reconnection state.
  @override
  ReconnectionState get state => _state;

  /// Stream of reconnection state changes.
  @override
  Stream<ReconnectionState> get stateStream => _stateController.stream;

  /// Sets the last known BPM value for display during reconnection.
  @override
  void setLastKnownBpm(int bpm) {
    _lastKnownBpm = bpm;
  }

  /// Sets the session ID to resume after successful reconnection.
  @override
  void setSessionIdToResume(int? sessionId) {
    _sessionIdToResume = sessionId;
  }

  /// Gets the session ID to resume after reconnection.
  @override
  int? get sessionIdToResume => _sessionIdToResume;

  /// Overrides the Bluetooth service (testing hook).
  @visibleForTesting
  @override
  set bluetoothService(BluetoothService service) {
    _bluetoothService = service;
  }

  /// Overrides reconnection delays (testing hook).
  @visibleForTesting
  @override
  set delayCalculator(Duration Function(int attempt) calculator) {
    _delayCalculator = calculator;
  }

  /// Marks that the next disconnection should be treated as manual.
  ///
  /// Call this before initiating a manual disconnect to prevent
  /// auto-reconnection attempts.
  @override
  void markManualDisconnect() {
    _wasManualDisconnect = true;
  }

  /// Starts monitoring for unexpected disconnections.
  ///
  /// [deviceId] is the ID of the currently connected device.
  /// When an unexpected disconnection occurs, reconnection attempts
  /// will begin automatically.
  @override
  void startMonitoring(String deviceId) {
    _targetDeviceId = deviceId;
    _wasManualDisconnect = false;
    _isReconnecting = false;

    // Cancel any existing subscription
    _connectionSubscription?.cancel();

    // Monitor connection state
    _connectionSubscription = _bluetoothService.monitorConnectionState().listen(
      (state) {
        if (state == ConnectionState.disconnected && !_wasManualDisconnect) {
          // Unexpected disconnection - start reconnection
          _startReconnection();
        } else if (state == ConnectionState.connected) {
          // Successfully reconnected
          _handleSuccessfulReconnection();
        }
      },
    );
  }

  /// Stops monitoring and cancels any pending reconnection attempts.
  @override
  void stopMonitoring() {
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
    _updateState(ReconnectionState.idle());
  }

  /// Manually triggers reconnection attempts.
  ///
  /// Useful when the user chooses to retry after all attempts have failed.
  @override
  Future<void> retryReconnection() async {
    if (_targetDeviceId == null) return;

    _updateState(ReconnectionState.idle());
    _startReconnection();
  }

  /// Starts the reconnection process.
  void _startReconnection() {
    if (_targetDeviceId == null) return;
    if (_isReconnecting) {
      // Already reconnecting; ignore duplicate
      return;
    }
    _isReconnecting = true;

    // Start from attempt 1
    _attemptReconnection(1);
  }

  /// Attempts to reconnect to the device.
  ///
  /// [attempt] is the current attempt number (1-based).
  Future<void> _attemptReconnection(int attempt) async {
    if (_targetDeviceId == null) return;

    // Check if we've exceeded max attempts
    if (attempt > maxReconnectionAttempts) {
      _updateState(
        ReconnectionState.failed(
          lastKnownBpm: _lastKnownBpm,
          errorMessage:
              'Could not reconnect after $maxReconnectionAttempts attempts.',
        ),
      );
      _isReconnecting = false;
      return;
    }

    // Update state to show current attempt
    _updateState(
      ReconnectionState.reconnecting(
        attempt: attempt,
        lastKnownBpm: _lastKnownBpm,
      ),
    );

    try {
      // Attempt to connect
      await _bluetoothService.connectToDevice(_targetDeviceId!);

      // If we get here, connection succeeded
      // The connection state listener will handle the success
    } catch (e) {
      // Connection failed - schedule next attempt
      final delay = _getDelayForAttempt(attempt);

      _reconnectionTimer?.cancel();
      _reconnectionTimer = Timer(delay, () {
        _attemptReconnection(attempt + 1);
      });
    } finally {
      // If no timer is scheduled (e.g., success path), ensure flag reset in success handler
    }
  }

  /// Handles a successful reconnection.
  void _handleSuccessfulReconnection() async {
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
    try {
      await _bluetoothService.restartHeartRateStream();
    } catch (_) {
      // Ignore errors here; state will still reset and UI can surface errors via provider.
    }
    _updateState(ReconnectionState.idle());
    _wasManualDisconnect = false;
    _isReconnecting = false;
  }

  /// Gets the delay before the next reconnection attempt.
  ///
  /// Uses exponential backoff:
  /// - Attempt 1: 2 seconds
  /// - Attempt 2: 4 seconds
  /// - Attempt 3: 8 seconds
  /// - Attempt 4+: 30 seconds
  Duration _getDelayForAttempt(int attempt) {
    return _delayCalculator(attempt);
  }

  static Duration _defaultDelayForAttempt(int attempt) {
    switch (attempt) {
      case 1:
        return const Duration(seconds: 2);
      case 2:
        return const Duration(seconds: 4);
      case 3:
        return const Duration(seconds: 8);
      default:
        return const Duration(seconds: 30);
    }
  }

  /// Updates the state and notifies listeners.
  void _updateState(ReconnectionState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  /// Resets the handler to initial state.
  @override
  void reset() {
    stopMonitoring();
    _targetDeviceId = null;
    _sessionIdToResume = null;
    _lastKnownBpm = null;
    _wasManualDisconnect = false;
    _isReconnecting = false;
  }

  /// Disposes of resources.
  @override
  Future<void> dispose() async {
    stopMonitoring();
    await _stateController.close();
  }
}
