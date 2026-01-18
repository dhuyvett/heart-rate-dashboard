// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 15))
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/heart_rate_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_rate_dashboard/providers/heart_rate_provider.dart';
import 'package:heart_rate_dashboard/providers/session_provider.dart';
import 'package:heart_rate_dashboard/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionNotifier integration with database', () {
    late ProviderContainer container;

    setUp(() async {
      sqfliteFfiInit();
      await DatabaseService.instance.initializeForTesting(databaseFactoryFfi);
      container = ProviderContainer(
        overrides: [
          heartRateProvider.overrideWith(
            (ref) => const Stream<HeartRateData>.empty(),
          ),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await DatabaseService.instance.closeForTesting();
    });

    test('deletes an empty session on endSession', () async {
      final notifier = container.read(sessionProvider.notifier);
      await notifier.startSession(
        deviceName: 'Test Device',
        sessionName: 'Integration Session',
        trackSpeedDistance: false,
      );
      final sessionId = container.read(sessionProvider).currentSessionId!;

      await notifier.endSession();
      final saved = await DatabaseService.instance.getSessionById(sessionId);

      expect(saved, isNull);
    });

    test('persists stats and readings when data exists', () async {
      final notifier = container.read(sessionProvider.notifier);
      await notifier.startSession(
        deviceName: 'Test Device',
        sessionName: 'Integration Session',
        trackSpeedDistance: false,
      );
      final sessionId = container.read(sessionProvider).currentSessionId!;

      await notifier.handleReadingForTest(110);
      await notifier.handleReadingForTest(90);

      expect(container.read(sessionProvider).readingsCount, 2);
      await notifier.endSession();

      final saved = await DatabaseService.instance.getSessionById(sessionId);
      final readings = await DatabaseService.instance.getReadingsBySession(
        sessionId,
      );

      expect(saved, isNotNull);
      expect(saved!.minHr, equals(90));
      expect(saved.maxHr, equals(110));
      expect(readings.length, equals(2));
    });
  });
}
