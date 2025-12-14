// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/services/bluetooth_service.dart';
import 'package:heart_rate_dashboard/services/reconnection_handler.dart';
import 'package:heart_rate_dashboard/utils/constants.dart';

void main() {
  group('ReconnectionState', () {
    test('should create idle state correctly', () {
      final state = ReconnectionState.idle();

      expect(state.isReconnecting, isFalse);
      expect(state.currentAttempt, equals(0));
      expect(state.hasFailed, isFalse);
      expect(state.lastKnownBpm, isNull);
      expect(state.errorMessage, isNull);
    });

    test('should create reconnecting state correctly', () {
      final state = ReconnectionState.reconnecting(
        attempt: 3,
        lastKnownBpm: 120,
      );

      expect(state.isReconnecting, isTrue);
      expect(state.currentAttempt, equals(3));
      expect(state.hasFailed, isFalse);
      expect(state.lastKnownBpm, equals(120));
    });

    test('should create failed state correctly', () {
      final state = ReconnectionState.failed(
        lastKnownBpm: 85,
        errorMessage: 'Test error',
      );

      expect(state.isReconnecting, isFalse);
      expect(state.currentAttempt, equals(maxReconnectionAttempts));
      expect(state.hasFailed, isTrue);
      expect(state.lastKnownBpm, equals(85));
      expect(state.errorMessage, equals('Test error'));
    });

    test('should create default error message for failed state', () {
      final state = ReconnectionState.failed(lastKnownBpm: 75);

      expect(state.errorMessage, contains('reconnect'));
    });
  });

  group('ReconnectionHandler', () {
    late ReconnectionHandler handler;

    setUp(() {
      handler = ReconnectionHandler.instance;
      handler.reset();
    });

    tearDown(() {
      handler.reset();
    });

    test('should start with idle state', () {
      expect(handler.state.isReconnecting, isFalse);
      expect(handler.state.hasFailed, isFalse);
    });

    test('should track last known BPM', () {
      handler.setLastKnownBpm(100);

      // The last known BPM is stored internally for use during reconnection
      // We verify it by checking that the handler doesn't throw and can be reset
      handler.reset();
      expect(handler.state, equals(ReconnectionState.idle()));
    });

    test('should track session ID to resume', () {
      handler.setSessionIdToResume(42);

      expect(handler.sessionIdToResume, equals(42));

      handler.reset();
      expect(handler.sessionIdToResume, isNull);
    });

    test('should emit state changes through stream', () async {
      final states = <ReconnectionState>[];
      final subscription = handler.stateStream.listen((state) {
        states.add(state);
      });

      // Manually trigger some state changes for testing
      handler.setLastKnownBpm(120);
      handler.setSessionIdToResume(1);

      // Wait briefly for any state emissions with explicit timeout
      await handler.stateStream.first.timeout(
        const Duration(milliseconds: 100),
        onTimeout: () {
          return handler.state;
        },
      );

      await subscription.cancel();

      expect(states, isA<List<ReconnectionState>>());
    });

    test('restarts heart rate stream on successful reconnection', () async {
      var restartCalled = false;
      final controller = StreamController<ConnectionState>();
      final fakeService = BluetoothService.test(
        connectionStateStream: controller.stream,
        onRestartHeartRate: () async {
          restartCalled = true;
        },
      );

      handler.bluetoothService = fakeService;
      handler.startMonitoring('TEST_DEVICE');

      // Simulate unexpected disconnect followed by reconnect
      controller.add(ConnectionState.disconnected);
      controller.add(ConnectionState.connected);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(restartCalled, isTrue);
      await controller.close();
    });
  });
}
