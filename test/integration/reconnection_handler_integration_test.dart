// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 15))
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/services/bluetooth_service.dart';
import 'package:heart_rate_dashboard/services/reconnection_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReconnectionHandler integration', () {
    late StreamController<ConnectionState> connectionStates;
    late StreamSubscription<ReconnectionState> subscription;
    late ReconnectionHandler handler;
    late List<ReconnectionState> observed;

    setUp(() {
      connectionStates = StreamController<ConnectionState>.broadcast();
      observed = [];
      handler = ReconnectionHandler.instance;
      handler.reset();
      handler.bluetoothService = BluetoothService.test(
        connectionStateStream: connectionStates.stream,
        onConnect: (_) async {},
      );
      handler.delayCalculator = (_) => const Duration(milliseconds: 10);
      subscription = handler.stateStream.listen(observed.add);
    });

    tearDown(() async {
      await subscription.cancel();
      await connectionStates.close();
      handler.reset();
    });

    test(
      'blocks duplicate reconnection attempts and clears state on success',
      () async {
        final connects = <String>[];
        handler.bluetoothService = BluetoothService.test(
          connectionStateStream: connectionStates.stream,
          onConnect: (deviceId) async => connects.add(deviceId),
        );

        handler.startMonitoring('device-1');
        connectionStates.add(ConnectionState.disconnected);
        connectionStates.add(ConnectionState.disconnected);

        await Future.delayed(const Duration(milliseconds: 30));
        connectionStates.add(ConnectionState.connected);
        await Future.delayed(const Duration(milliseconds: 20));

        expect(connects, ['device-1']);
        expect(handler.state.isReconnecting, isFalse);
        expect(observed.any((s) => s.isReconnecting), isTrue);
      },
    );

    test('retries after a failure and clears the reconnecting flag', () async {
      var attempts = 0;
      handler.bluetoothService = BluetoothService.test(
        connectionStateStream: connectionStates.stream,
        onConnect: (_) async {
          attempts++;
          if (attempts == 1) throw TimeoutException('fail once');
        },
      );

      handler.startMonitoring('device-2');
      connectionStates.add(ConnectionState.disconnected);

      await Future.delayed(const Duration(milliseconds: 50));
      connectionStates.add(ConnectionState.connected);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(attempts, 2);
      expect(handler.state.isReconnecting, isFalse);
      expect(observed.where((s) => s.currentAttempt == 2).isNotEmpty, isTrue);
    });
  });
}
