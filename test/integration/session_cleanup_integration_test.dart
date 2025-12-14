// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Session cleanup', () {
    setUp(() async {
      sqfliteFfiInit();
      await DatabaseService.instance.initializeForTesting(databaseFactoryFfi);
    });

    tearDown(() async {
      await DatabaseService.instance.closeForTesting();
    });

    test('deletes empty active session when no readings exist', () async {
      final sessionId = await DatabaseService.instance.createSession(
        deviceName: 'Test Device',
        name: 'Crashed Session',
      );

      await DatabaseService.instance.completeActiveSessionWithLastReading();

      final session = await DatabaseService.instance.getSessionById(sessionId);
      expect(session, isNull);
    });

    test('reconstructs stats for interrupted session', () async {
      final db = DatabaseService.instance;
      final sessionId = await db.createSession(
        deviceName: 'Test Device',
        name: 'Crashed Session',
      );

      final firstReadingTime = DateTime(2024, 1, 1, 12);
      await db.insertHeartRateReading(sessionId, firstReadingTime, 100);
      await db.insertHeartRateReading(
        sessionId,
        firstReadingTime.add(const Duration(seconds: 5)),
        80,
      );

      await db.completeActiveSessionWithLastReading();

      final session = await db.getSessionById(sessionId);

      expect(session, isNotNull);
      expect(session!.avgHr, equals(90));
      expect(session.minHr, equals(80));
      expect(session.maxHr, equals(100));
      expect(
        session.endTime,
        equals(firstReadingTime.add(const Duration(seconds: 5))),
      );
      expect(await db.getCurrentSession(), isNull);
    });
  });
}
