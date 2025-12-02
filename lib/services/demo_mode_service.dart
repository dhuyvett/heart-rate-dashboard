import 'dart:async';
import 'dart:math';
import '../utils/constants.dart';

/// Service for generating simulated heart rate data in demo mode.
///
/// This service creates realistic heart rate patterns without requiring
/// a physical Bluetooth heart rate monitor. It simulates:
/// - Natural variability (small fluctuations between readings)
/// - Gradual trends (increases and decreases over 30-60 second periods)
/// - Realistic BPM ranges (60-180 BPM)
///
/// The demo mode service behaves identically to a real device from the
/// UI perspective, emitting values at the same 1.5-second intervals.
class DemoModeService {
  // Singleton instance
  static final DemoModeService instance = DemoModeService._internal();

  // Stream controller for heart rate values
  StreamController<int>? _heartRateController;

  // Timer for periodic value generation
  Timer? _timer;

  // Random number generator for variability
  final Random _random = Random();

  // Current simulation state
  double _currentBpm = 75.0;
  double _targetBpm = 75.0;
  int _samplesUntilTrendChange = 0;

  // Whether demo mode is currently active
  bool _isActive = false;

  // Private constructor for singleton
  DemoModeService._internal();

  /// Whether demo mode is currently running.
  bool get isActive => _isActive;

  /// Starts demo mode and begins generating simulated heart rate data.
  ///
  /// The generated values follow realistic patterns:
  /// - Base range: 60-180 BPM
  /// - Natural variability: +/-2-5 BPM per sample
  /// - Gradual trends: increase/decrease over 30-60 second periods
  /// - Uses sine wave with noise for realistic patterns
  ///
  /// Values are emitted at 1.5-second intervals to match real device
  /// sampling rate.
  void startDemoMode() {
    if (_isActive) return;

    StreamController<int>? controller;

    try {
      controller = StreamController<int>.broadcast();
      _heartRateController = controller;
      _isActive = true;

      // Initialize simulation state
      _currentBpm = 70.0 + _random.nextDouble() * 20; // Start between 70-90
      _targetBpm = _currentBpm;
      _samplesUntilTrendChange = _calculateSamplesUntilTrendChange();

      // Start generating values
      _timer = Timer.periodic(
        const Duration(milliseconds: hrSamplingIntervalMs),
        (_) => _generateNextValue(),
      );
    } catch (e) {
      controller?.close();
      _isActive = false;
      rethrow;
    }
  }

  /// Returns a stream of simulated BPM values.
  ///
  /// Must call [startDemoMode] first to begin generating values.
  /// The stream will emit integer BPM values at regular intervals.
  Stream<int> getDemoModeStream() {
    if (_heartRateController == null) {
      throw StateError('Demo mode not started. Call startDemoMode() first.');
    }
    return _heartRateController!.stream;
  }

  /// Stops demo mode and cleans up resources.
  ///
  /// After calling this method, no more values will be emitted.
  /// Call [startDemoMode] to restart demo mode.
  void stopDemoMode() {
    _isActive = false;
    _timer?.cancel();
    _timer = null;
    _heartRateController?.close();
    _heartRateController = null;
  }

  /// Generates the next simulated heart rate value.
  ///
  /// Uses a combination of:
  /// 1. Gradual movement toward a target BPM
  /// 2. Natural variability (noise)
  /// 3. Periodic trend changes
  void _generateNextValue() {
    if (_heartRateController == null || _heartRateController!.isClosed) return;

    // Decrease samples until trend change
    _samplesUntilTrendChange--;

    // Check if it's time to change trend
    if (_samplesUntilTrendChange <= 0) {
      _changeTrend();
    }

    // Move current BPM toward target with variability
    _currentBpm = _calculateNextBpm();

    // Emit the rounded value
    final bpmValue = _currentBpm.round().clamp(60, 180);
    _heartRateController!.add(bpmValue);
  }

  /// Calculates the next BPM value with smooth transitions and variability.
  double _calculateNextBpm() {
    // Use a smoothing factor to gradually approach target
    const smoothingFactor = 0.1;
    final baseChange = (_targetBpm - _currentBpm) * smoothingFactor;

    // Add natural variability (+/- 2-5 BPM)
    final variability = (_random.nextDouble() - 0.5) * 5;

    // Add slight sine wave component for more natural rhythm
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final sineComponent = sin(time * 0.5) * 2;

    // Calculate new BPM
    double newBpm =
        _currentBpm + baseChange + variability + sineComponent * 0.3;

    // Clamp to realistic range
    return newBpm.clamp(55.0, 185.0);
  }

  /// Changes the current trend direction and sets a new target BPM.
  void _changeTrend() {
    // Decide whether to increase, decrease, or stabilize
    final decision = _random.nextDouble();

    if (decision < 0.4) {
      // 40% chance: Move toward a higher BPM (simulating exercise)
      _targetBpm = _currentBpm + _random.nextDouble() * 30 + 10; // +10 to +40
    } else if (decision < 0.8) {
      // 40% chance: Move toward a lower BPM (simulating rest)
      _targetBpm = _currentBpm - _random.nextDouble() * 20 - 5; // -5 to -25
    } else {
      // 20% chance: Stay relatively stable
      _targetBpm = _currentBpm + (_random.nextDouble() - 0.5) * 10; // +/- 5
    }

    // Clamp target to realistic range
    _targetBpm = _targetBpm.clamp(60.0, 180.0);

    // Set samples until next trend change (30-60 seconds at 1.5s intervals)
    _samplesUntilTrendChange = _calculateSamplesUntilTrendChange();
  }

  /// Calculates random number of samples until the next trend change.
  ///
  /// Returns a value representing 30-60 seconds of samples at the
  /// configured sampling rate.
  int _calculateSamplesUntilTrendChange() {
    // 30-60 seconds, at 1.5 second intervals = 20-40 samples
    return 20 + _random.nextInt(21);
  }

  /// Gets the current simulated BPM value.
  ///
  /// Useful for displaying the last known value during reconnection.
  int? getCurrentBpm() {
    if (!_isActive) return null;
    return _currentBpm.round().clamp(60, 180);
  }

  /// Resets the demo mode to initial state.
  ///
  /// Useful for testing or starting fresh.
  void reset() {
    stopDemoMode();
    _currentBpm = 75.0;
    _targetBpm = 75.0;
    _samplesUntilTrendChange = 0;
  }
}
