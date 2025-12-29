// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/app_settings.dart';
import 'package:heart_rate_dashboard/models/heart_rate_data.dart';
import 'package:heart_rate_dashboard/models/heart_rate_zone.dart';
import 'package:heart_rate_dashboard/models/scanned_device.dart';
import 'package:heart_rate_dashboard/models/session_state.dart';
import 'package:heart_rate_dashboard/providers/bluetooth_provider.dart';
import 'package:heart_rate_dashboard/providers/device_scan_provider.dart';
import 'package:heart_rate_dashboard/providers/heart_rate_provider.dart';
import 'package:heart_rate_dashboard/providers/reconnection_handler_provider.dart';
import 'package:heart_rate_dashboard/providers/settings_provider.dart';
import 'package:heart_rate_dashboard/providers/session_provider.dart';
import 'package:heart_rate_dashboard/screens/device_selection_screen.dart';
import 'package:heart_rate_dashboard/screens/heart_rate_monitoring_screen.dart';
import 'package:heart_rate_dashboard/services/bluetooth_service.dart' as bt;
import 'package:heart_rate_dashboard/services/database_service.dart';
import 'package:heart_rate_dashboard/services/reconnection_handler.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_settings_notifier.dart';

class _FakeReconnectionHandler implements ReconnectionController {
  bool manualDisconnectMarked = false;

  @override
  void markManualDisconnect() {
    manualDisconnectMarked = true;
  }

  @override
  Stream<ReconnectionState> get stateStream =>
      const Stream<ReconnectionState>.empty();

  @override
  ReconnectionState get state => ReconnectionState.idle();

  @override
  void setLastKnownBpm(int bpm) {}

  @override
  void setSessionIdToResume(int? sessionId) {}

  @override
  int? get sessionIdToResume => null;

  @override
  set bluetoothService(bt.BluetoothService service) {}

  @override
  set delayCalculator(Duration Function(int attempt) calculator) {}

  @override
  Future<void> retryReconnection() async {}

  @override
  void startMonitoring(String deviceId) {}

  @override
  void stopMonitoring() {}

  @override
  void reset() {}

  @override
  Future<void> dispose() async {}
}

class _NoopSessionNotifier extends SessionNotifier {
  _NoopSessionNotifier(this._state);

  final SessionState _state;

  @override
  SessionState build() => _state;

  @override
  Future<void> startSession({
    required String deviceName,
    required String sessionName,
  }) async {}

  @override
  Future<void> endSession() async {}
}

class _NavigationHost extends StatefulWidget {
  const _NavigationHost({required this.monitoringBuilder});

  final WidgetBuilder monitoringBuilder;

  @override
  State<_NavigationHost> createState() => _NavigationHostState();
}

class _NavigationHostState extends State<_NavigationHost> {
  var _pushed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pushed) return;
    _pushed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: widget.monitoringBuilder));
    });
  }

  @override
  Widget build(BuildContext context) => const DeviceSelectionScreen();
}

Widget _buildMonitoringScreen(BuildContext context) =>
    const HeartRateMonitoringScreen(
      deviceName: 'Polar',
      sessionName: 'Test Session',
      enableSessionRestore: false,
      loadRecentReadings: false,
    );

class _FlakySessionNotifier extends SessionNotifier {
  _FlakySessionNotifier(this._state);

  final SessionState _state;
  int startCalls = 0;
  bool _failNext = true;

  @override
  SessionState build() => _state;

  @override
  Future<void> startSession({
    required String deviceName,
    required String sessionName,
  }) async {
    startCalls += 1;
    if (_failNext) {
      _failNext = false;
      throw StateError('start failed');
    }
  }

  @override
  Future<void> endSession() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  setUpAll(() async {
    await DatabaseService.instance.initializeForTesting(databaseFactoryFfi);
  });

  setUp(() {
    bt.BluetoothService.debugInstance = bt.BluetoothService.test(
      connectionStateStream: const Stream<bt.ConnectionState>.empty(),
    );
  });

  group('HeartRateMonitoringScreen', () {
    testWidgets('shows loading/error states from providers', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heartRateProvider.overrideWith(
              (ref) => Stream<HeartRateData>.error('failed'),
            ),
            settingsProvider.overrideWith(
              () => FakeSettingsNotifier(const AppSettings()),
            ),
            sessionProvider.overrideWith(
              () => _NoopSessionNotifier(SessionState.inactive()),
            ),
          ],
          child: const MaterialApp(
            home: HeartRateMonitoringScreen(
              deviceName: 'Polar',
              sessionName: 'Test Session',
              enableSessionRestore: false,
              loadRecentReadings: false,
              onChangeDevice: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.textContaining('---'), findsWidgets);
    });

    testWidgets('renders live BPM and zone label when data arrives', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heartRateProvider.overrideWith(
              (ref) => Stream.value(
                HeartRateData(
                  bpm: 150,
                  zone: HeartRateZone.zone4,
                  receivedAt: DateTime(2024, 1, 1),
                ),
              ),
            ),
            settingsProvider.overrideWith(
              () => FakeSettingsNotifier(const AppSettings()),
            ),
            sessionProvider.overrideWith(
              () => _NoopSessionNotifier(
                SessionState(
                  currentSessionId: 1,
                  startTime: DateTime.now(),
                  duration: const Duration(minutes: 5),
                  avgHr: 140,
                  minHr: 120,
                  maxHr: 160,
                  readingsCount: 100,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: HeartRateMonitoringScreen(
              deviceName: 'Polar',
              sessionName: 'Test Session',
              enableSessionRestore: false,
              loadRecentReadings: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text('150'), findsOneWidget);
      expect(find.textContaining('Zone 4'), findsOneWidget);
    });

    testWidgets('sets up heart rate listener only once across rebuilds', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = StreamController<HeartRateData>.broadcast();
      addTearDown(controller.close);
      var callbackCount = 0;

      final sessionState = SessionState(
        currentSessionId: 1,
        startTime: DateTime.now(),
        duration: Duration.zero,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heartRateProvider.overrideWith((ref) => controller.stream),
            settingsProvider.overrideWith(
              () => FakeSettingsNotifier(const AppSettings()),
            ),
            sessionProvider.overrideWith(
              () => _NoopSessionNotifier(sessionState),
            ),
            bluetoothConnectionProvider.overrideWith(
              (ref) => Stream.value(
                BluetoothConnectionInfo(
                  connectionState: bt.ConnectionState.connected,
                  deviceName: 'Test Device',
                ),
              ),
            ),
          ],
          child: MaterialApp(
            home: HeartRateMonitoringScreen(
              deviceName: 'Polar',
              sessionName: 'Test Session',
              enableSessionRestore: false,
              loadRecentReadings: false,
              onHeartRateUpdate: () {
                callbackCount++;
              },
            ),
          ),
        ),
      );

      // Trigger rebuilds; the old implementation would add a new listener each time.
      await tester.pump();
      await tester.pump();

      controller.add(
        HeartRateData(
          bpm: 120,
          zone: HeartRateZone.zone2,
          receivedAt: DateTime(2024, 1, 1),
        ),
      );
      await tester.pump();

      expect(callbackCount, equals(1));
    });

    testWidgets('marks manual disconnect when changing device', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeReconnection = _FakeReconnectionHandler();
      var changeDeviceCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heartRateProvider.overrideWith((ref) => const Stream.empty()),
            settingsProvider.overrideWith(
              () => FakeSettingsNotifier(const AppSettings()),
            ),
            sessionProvider.overrideWith(
              () => _NoopSessionNotifier(SessionState.inactive()),
            ),
            bluetoothConnectionProvider.overrideWith(
              (ref) => Stream.value(
                BluetoothConnectionInfo(
                  connectionState: bt.ConnectionState.connected,
                  deviceName: 'Test Device',
                ),
              ),
            ),
            reconnectionHandlerProvider.overrideWith((ref) => fakeReconnection),
          ],
          child: MaterialApp(
            home: HeartRateMonitoringScreen(
              deviceName: 'Polar',
              sessionName: 'Test Session',
              enableSessionRestore: false,
              loadRecentReadings: false,
              onChangeDevice: () {
                changeDeviceCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      final state =
          tester.state(find.byType(HeartRateMonitoringScreen)) as dynamic;
      await state.triggerChangeDevice();

      expect(fakeReconnection.manualDisconnectMarked, isTrue);
      expect(changeDeviceCalled, isTrue);
    });

    testWidgets('end session returns to device selection without back button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heartRateProvider.overrideWith((ref) => const Stream.empty()),
            settingsProvider.overrideWith(
              () => FakeSettingsNotifier(const AppSettings()),
            ),
            sessionProvider.overrideWith(
              () => _NoopSessionNotifier(SessionState.inactive()),
            ),
            bluetoothConnectionProvider.overrideWith(
              (ref) => Stream.value(
                BluetoothConnectionInfo(
                  connectionState: bt.ConnectionState.connected,
                  deviceName: 'Test Device',
                ),
              ),
            ),
            deviceScanProvider.overrideWith(
              (ref) => Stream.value([ScannedDevice.demoMode()]),
            ),
          ],
          child: MaterialApp(
            home: _NavigationHost(monitoringBuilder: _buildMonitoringScreen),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byType(HeartRateMonitoringScreen), findsOneWidget);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isTrue);
      final state =
          tester.state(find.byType(HeartRateMonitoringScreen)) as dynamic;
      unawaited(state.triggerEndSessionForTest());
      await tester.pump(const Duration(seconds: 2));

      expect(navigator.canPop(), isFalse);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios), findsNothing);
    });

    testWidgets('retries session start after failure', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final flakyNotifier = _FlakySessionNotifier(SessionState.inactive());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heartRateProvider.overrideWith((ref) => const Stream.empty()),
            settingsProvider.overrideWith(
              () => FakeSettingsNotifier(const AppSettings()),
            ),
            sessionProvider.overrideWith(() => flakyNotifier),
          ],
          child: const MaterialApp(
            home: HeartRateMonitoringScreen(
              deviceName: 'Polar',
              sessionName: 'Test Session',
              enableSessionRestore: false,
              loadRecentReadings: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(flakyNotifier.startCalls, equals(1));

      final state =
          tester.state(find.byType(HeartRateMonitoringScreen)) as dynamic;
      await state.triggerStartSessionForTest();
      await tester.pump(const Duration(milliseconds: 200));

      expect(flakyNotifier.startCalls, equals(2));
    });
  });
}
