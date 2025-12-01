// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/scanned_device.dart';
import 'package:heart_rate_dashboard/services/bluetooth_service.dart'
    as bt_service;
import 'package:heart_rate_dashboard/widgets/connection_status_indicator.dart';
import 'package:heart_rate_dashboard/widgets/session_stats_card.dart';
import 'package:heart_rate_dashboard/widgets/device_list_tile.dart';
import 'package:heart_rate_dashboard/widgets/loading_overlay.dart';
import 'package:heart_rate_dashboard/widgets/error_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectionStatusIndicator', () {
    testWidgets('displays green for connected state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConnectionStatusIndicator(
              connectionState: bt_service.ConnectionState.connected,
            ),
          ),
        ),
      );

      // Find the container with circular decoration
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.green));
    });

    testWidgets('displays red for disconnected state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConnectionStatusIndicator(
              connectionState: bt_service.ConnectionState.disconnected,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.red));
    });

    testWidgets('displays pulsing animation for reconnecting state', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConnectionStatusIndicator(
              connectionState: bt_service.ConnectionState.reconnecting,
            ),
          ),
        ),
      );

      // Should have Opacity widget for pulsing effect
      expect(find.byType(Opacity), findsOneWidget);
      // Transform.scale is used in the pulsing animation
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('displays yellow for connecting state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConnectionStatusIndicator(
              connectionState: bt_service.ConnectionState.connecting,
            ),
          ),
        ),
      );

      // Connecting state shows yellow color (same as reconnecting but without pulsing)
      // According to source, only reconnecting pulses
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.yellow));
    });
  });

  group('SessionStatsCard', () {
    testWidgets('displays icon, label, and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SessionStatsCard(
              icon: Icons.favorite,
              label: 'Average',
              value: '142 BPM',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text('Average'), findsOneWidget);
      expect(find.text('142 BPM'), findsOneWidget);
    });

    testWidgets('uses custom icon color when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SessionStatsCard(
              icon: Icons.timer,
              label: 'Duration',
              value: '10:30',
              iconColor: Colors.red,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.timer));
      expect(icon.color, equals(Colors.red));
    });

    testWidgets('displays Card widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SessionStatsCard(
              icon: Icons.trending_up,
              label: 'Max',
              value: '180 BPM',
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('DeviceListTile', () {
    testWidgets('displays device name', (tester) async {
      const device = ScannedDevice(id: 'test-id', name: 'Polar H10', rssi: -60);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListTile(device: device, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Polar H10'), findsOneWidget);
    });

    testWidgets('shows bluetooth icon for regular devices', (tester) async {
      const device = ScannedDevice(
        id: 'test-id',
        name: 'Regular Device',
        rssi: -70,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListTile(device: device, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.bluetooth), findsOneWidget);
    });

    testWidgets('shows psychology icon for demo device', (tester) async {
      final device = ScannedDevice.demoMode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListTile(device: device, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.psychology), findsOneWidget);
      expect(find.text('Demo Mode'), findsOneWidget);
      expect(
        find.text('Simulated heart rate data for testing'),
        findsOneWidget,
      );
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      const device = ScannedDevice(
        id: 'test-id',
        name: 'Test Device',
        rssi: -50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListTile(device: device, onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('displays signal strength indicator for regular device', (
      tester,
    ) async {
      const device = ScannedDevice(
        id: 'test-id',
        name: 'Test Device',
        rssi: -50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListTile(device: device, onTap: () {}),
          ),
        ),
      );

      // Signal strength indicator shows 5 bars
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('does not show signal indicator for demo device', (
      tester,
    ) async {
      final device = ScannedDevice.demoMode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceListTile(device: device, onTap: () {}),
          ),
        ),
      );

      // Demo devices don't have signal strength indicator in trailing
      // The trailing is null for demo devices
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.trailing, isNull);
    });
  });

  group('LoadingOverlay', () {
    testWidgets('displays circular progress indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LoadingOverlay())),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingOverlay(message: 'Loading...')),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('displays submessage when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              message: 'Connecting',
              submessage: 'Please wait...',
            ),
          ),
        ),
      );

      expect(find.text('Connecting'), findsOneWidget);
      expect(find.text('Please wait...'), findsOneWidget);
    });

    testWidgets('shows card by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingOverlay(message: 'Test')),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('hides card when showCard is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(message: 'Test', showCard: false),
          ),
        ),
      );

      expect(find.byType(Card), findsNothing);
    });
  });

  group('ReconnectionOverlay', () {
    testWidgets('displays reconnection message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ReconnectionOverlay(currentAttempt: 3)),
        ),
      );

      expect(find.text('Reconnecting...'), findsOneWidget);
      expect(find.text('Attempt 3 of 10'), findsOneWidget);
    });

    testWidgets('displays custom max attempts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReconnectionOverlay(currentAttempt: 5, maxAttempts: 15),
          ),
        ),
      );

      expect(find.text('Attempt 5 of 15'), findsOneWidget);
    });

    testWidgets('displays last known BPM when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReconnectionOverlay(currentAttempt: 2, lastKnownBpm: 140),
          ),
        ),
      );

      expect(find.text('Last: 140 BPM'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('hides last BPM section when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ReconnectionOverlay(currentAttempt: 2)),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsNothing);
    });
  });

  group('InlineLoadingIndicator', () {
    testWidgets('displays only spinner when no message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: InlineLoadingIndicator())),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('displays spinner and message when message provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InlineLoadingIndicator(message: 'Loading data...'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading data...'), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });
  });

  group('ErrorDialogAction', () {
    test('creates action with required fields', () {
      final action = ErrorDialogAction(label: 'Retry', onPressed: () {});

      expect(action.label, equals('Retry'));
      expect(action.isPrimary, isFalse);
    });

    test('creates primary action', () {
      final action = ErrorDialogAction(
        label: 'OK',
        onPressed: () {},
        isPrimary: true,
      );

      expect(action.isPrimary, isTrue);
    });
  });

  group('ErrorDialog', () {
    testWidgets('displays title and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ErrorDialog(
                      title: 'Error Title',
                      message: 'Error message here',
                      actions: [
                        ErrorDialogAction(label: 'OK', onPressed: () {}),
                      ],
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.text('Error Title'), findsOneWidget);
      expect(find.text('Error message here'), findsOneWidget);
    });

    testWidgets('displays default error icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ErrorDialog(
                      title: 'Error',
                      message: 'Something went wrong',
                      actions: [
                        ErrorDialogAction(label: 'OK', onPressed: () {}),
                      ],
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays custom icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ErrorDialog(
                      title: 'Bluetooth Error',
                      message: 'Connection lost',
                      icon: Icons.bluetooth_disabled,
                      actions: [
                        ErrorDialogAction(label: 'OK', onPressed: () {}),
                      ],
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.byIcon(Icons.bluetooth_disabled), findsOneWidget);
    });

    testWidgets('displays FilledButton for primary action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ErrorDialog(
                      title: 'Error',
                      message: 'Message',
                      actions: [
                        ErrorDialogAction(
                          label: 'Primary',
                          onPressed: () {},
                          isPrimary: true,
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Primary'), findsOneWidget);
    });

    testWidgets('displays TextButton for non-primary action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ErrorDialog(
                      title: 'Error',
                      message: 'Message',
                      actions: [
                        ErrorDialogAction(label: 'Cancel', onPressed: () {}),
                      ],
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('action callback is called when pressed', (tester) async {
      bool actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => ErrorDialog(
                      title: 'Error',
                      message: 'Message',
                      actions: [
                        ErrorDialogAction(
                          label: 'OK',
                          onPressed: () {
                            actionCalled = true;
                            Navigator.of(dialogContext).pop();
                          },
                          isPrimary: true,
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(actionCalled, isTrue);
    });
  });

  group('showSimpleErrorDialog', () {
    testWidgets('displays dialog with OK button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showSimpleErrorDialog(
                    context: context,
                    title: 'Simple Error',
                    message: 'Something went wrong',
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.text('Simple Error'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('closes when OK is pressed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showSimpleErrorDialog(
                    context: context,
                    title: 'Error',
                    message: 'Message',
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.text('Error'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.text('Error'), findsNothing);
    });
  });

  group('showConnectionFailedDialog', () {
    testWidgets('displays dialog with retry and select options', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showConnectionFailedDialog(
                    context: context,
                    deviceName: 'Polar H10',
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.text('Connection Failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Select Device'), findsOneWidget);
    });

    testWidgets('returns true when retry is pressed', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showConnectionFailedDialog(
                    context: context,
                    deviceName: 'Test',
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(result, isTrue);
    });

    testWidgets('returns false when select device is pressed', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showConnectionFailedDialog(
                    context: context,
                    deviceName: 'Test',
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      await tester.tap(find.text('Select Device'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(result, isFalse);
    });

    testWidgets('displays attempt count when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showConnectionFailedDialog(context: context, attemptCount: 5);
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.textContaining('5 attempts'), findsOneWidget);
    });
  });
}
