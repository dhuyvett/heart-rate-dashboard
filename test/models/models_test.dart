import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/heart_rate_reading.dart';
import 'package:heart_rate_dashboard/models/workout_session.dart';
import 'package:heart_rate_dashboard/models/session_state.dart';
import 'package:heart_rate_dashboard/models/app_settings.dart';
import 'package:heart_rate_dashboard/models/heart_rate_data.dart';
import 'package:heart_rate_dashboard/models/heart_rate_zone.dart';
import 'package:heart_rate_dashboard/models/scanned_device.dart';
import 'package:heart_rate_dashboard/utils/constants.dart';

void main() {
  group('HeartRateReading', () {
    test('creates valid reading with required fields', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final reading = HeartRateReading(
        sessionId: 1,
        timestamp: timestamp,
        bpm: 75,
      );

      expect(reading.id, isNull);
      expect(reading.sessionId, equals(1));
      expect(reading.timestamp, equals(timestamp));
      expect(reading.bpm, equals(75));
    });

    test('creates reading with optional id', () {
      final reading = HeartRateReading(
        id: 42,
        sessionId: 1,
        timestamp: DateTime.now(),
        bpm: 100,
      );

      expect(reading.id, equals(42));
    });

    test('throws ArgumentError for BPM below 30', () {
      expect(
        () =>
            HeartRateReading(sessionId: 1, timestamp: DateTime.now(), bpm: 29),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for BPM above 250', () {
      expect(
        () =>
            HeartRateReading(sessionId: 1, timestamp: DateTime.now(), bpm: 251),
        throwsArgumentError,
      );
    });

    test('accepts BPM at lower boundary (30)', () {
      final reading = HeartRateReading(
        sessionId: 1,
        timestamp: DateTime.now(),
        bpm: 30,
      );
      expect(reading.bpm, equals(30));
    });

    test('accepts BPM at upper boundary (250)', () {
      final reading = HeartRateReading(
        sessionId: 1,
        timestamp: DateTime.now(),
        bpm: 250,
      );
      expect(reading.bpm, equals(250));
    });

    test('toMap converts reading correctly', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final reading = HeartRateReading(
        id: 5,
        sessionId: 1,
        timestamp: timestamp,
        bpm: 80,
      );

      final map = reading.toMap();

      expect(map['id'], equals(5));
      expect(map['session_id'], equals(1));
      expect(map['timestamp'], equals(timestamp.millisecondsSinceEpoch));
      expect(map['bpm'], equals(80));
    });

    test('toMap excludes id when null', () {
      final reading = HeartRateReading(
        sessionId: 1,
        timestamp: DateTime.now(),
        bpm: 80,
      );

      final map = reading.toMap();

      expect(map.containsKey('id'), isFalse);
    });

    test('fromMap creates reading correctly', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final map = {
        'id': 10,
        'session_id': 2,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'bpm': 90,
      };

      final reading = HeartRateReading.fromMap(map);

      expect(reading.id, equals(10));
      expect(reading.sessionId, equals(2));
      expect(reading.timestamp, equals(timestamp));
      expect(reading.bpm, equals(90));
    });

    test('fromMap handles null id', () {
      final map = {
        'id': null,
        'session_id': 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'bpm': 75,
      };

      final reading = HeartRateReading.fromMap(map);

      expect(reading.id, isNull);
    });

    test('equality works correctly', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final reading1 = HeartRateReading(
        id: 1,
        sessionId: 1,
        timestamp: timestamp,
        bpm: 80,
      );
      final reading2 = HeartRateReading(
        id: 1,
        sessionId: 1,
        timestamp: timestamp,
        bpm: 80,
      );
      final reading3 = HeartRateReading(
        id: 2,
        sessionId: 1,
        timestamp: timestamp,
        bpm: 80,
      );

      expect(reading1 == reading2, isTrue);
      expect(reading1 == reading3, isFalse);
      expect(reading1.hashCode, equals(reading2.hashCode));
    });

    test('toString returns expected format', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final reading = HeartRateReading(
        id: 1,
        sessionId: 2,
        timestamp: timestamp,
        bpm: 75,
      );

      final str = reading.toString();

      expect(str, contains('HeartRateReading'));
      expect(str, contains('id: 1'));
      expect(str, contains('sessionId: 2'));
      expect(str, contains('bpm: 75'));
    });
  });

  group('WorkoutSession', () {
    test('creates session with required fields', () {
      final startTime = DateTime(2024, 1, 1, 10, 0, 0);
      final session = WorkoutSession(
        startTime: startTime,
        deviceName: 'Test Device',
      );

      expect(session.id, isNull);
      expect(session.startTime, equals(startTime));
      expect(session.endTime, isNull);
      expect(session.deviceName, equals('Test Device'));
      expect(session.avgHr, isNull);
      expect(session.minHr, isNull);
      expect(session.maxHr, isNull);
    });

    test('creates session with all fields', () {
      final startTime = DateTime(2024, 1, 1, 10, 0, 0);
      final endTime = DateTime(2024, 1, 1, 11, 0, 0);
      final session = WorkoutSession(
        id: 1,
        startTime: startTime,
        endTime: endTime,
        deviceName: 'Polar H10',
        avgHr: 140,
        minHr: 80,
        maxHr: 180,
      );

      expect(session.id, equals(1));
      expect(session.endTime, equals(endTime));
      expect(session.avgHr, equals(140));
      expect(session.minHr, equals(80));
      expect(session.maxHr, equals(180));
    });

    test('isActive returns true when endTime is null', () {
      final session = WorkoutSession(
        startTime: DateTime.now(),
        deviceName: 'Test',
      );

      expect(session.isActive, isTrue);
    });

    test('isActive returns false when endTime is set', () {
      final session = WorkoutSession(
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        deviceName: 'Test',
      );

      expect(session.isActive, isFalse);
    });

    test('getDuration calculates duration from start to end', () {
      final startTime = DateTime(2024, 1, 1, 10, 0, 0);
      final endTime = DateTime(2024, 1, 1, 10, 30, 0);
      final session = WorkoutSession(
        startTime: startTime,
        endTime: endTime,
        deviceName: 'Test',
      );

      expect(session.getDuration(), equals(const Duration(minutes: 30)));
    });

    test('toMap converts session correctly', () {
      final startTime = DateTime(2024, 1, 1, 10, 0, 0);
      final endTime = DateTime(2024, 1, 1, 11, 0, 0);
      final session = WorkoutSession(
        id: 5,
        startTime: startTime,
        endTime: endTime,
        deviceName: 'Polar H10',
        avgHr: 130,
        minHr: 70,
        maxHr: 175,
      );

      final map = session.toMap();

      expect(map['id'], equals(5));
      expect(map['start_time'], equals(startTime.millisecondsSinceEpoch));
      expect(map['end_time'], equals(endTime.millisecondsSinceEpoch));
      expect(map['device_name'], equals('Polar H10'));
      expect(map['avg_hr'], equals(130));
      expect(map['min_hr'], equals(70));
      expect(map['max_hr'], equals(175));
    });

    test('toMap handles null values correctly', () {
      final session = WorkoutSession(
        startTime: DateTime.now(),
        deviceName: 'Test',
      );

      final map = session.toMap();

      expect(map.containsKey('id'), isFalse);
      expect(map['end_time'], isNull);
      expect(map['avg_hr'], isNull);
      expect(map['min_hr'], isNull);
      expect(map['max_hr'], isNull);
    });

    test('fromMap creates session correctly', () {
      final startTime = DateTime(2024, 1, 1, 10, 0, 0);
      final endTime = DateTime(2024, 1, 1, 11, 0, 0);
      final map = {
        'id': 10,
        'start_time': startTime.millisecondsSinceEpoch,
        'end_time': endTime.millisecondsSinceEpoch,
        'device_name': 'Garmin HRM',
        'avg_hr': 145,
        'min_hr': 85,
        'max_hr': 190,
      };

      final session = WorkoutSession.fromMap(map);

      expect(session.id, equals(10));
      expect(session.startTime, equals(startTime));
      expect(session.endTime, equals(endTime));
      expect(session.deviceName, equals('Garmin HRM'));
      expect(session.avgHr, equals(145));
      expect(session.minHr, equals(85));
      expect(session.maxHr, equals(190));
    });

    test('fromMap handles null values', () {
      final startTime = DateTime(2024, 1, 1, 10, 0, 0);
      final map = {
        'id': null,
        'start_time': startTime.millisecondsSinceEpoch,
        'end_time': null,
        'device_name': 'Test',
        'avg_hr': null,
        'min_hr': null,
        'max_hr': null,
      };

      final session = WorkoutSession.fromMap(map);

      expect(session.id, isNull);
      expect(session.endTime, isNull);
      expect(session.avgHr, isNull);
    });

    test('copyWith updates specified fields', () {
      final session = WorkoutSession(
        id: 1,
        startTime: DateTime(2024, 1, 1),
        deviceName: 'Test',
      );

      final updated = session.copyWith(
        avgHr: 140,
        minHr: 80,
        maxHr: 180,
        endTime: DateTime(2024, 1, 1, 1, 0, 0),
      );

      expect(updated.id, equals(1)); // unchanged
      expect(updated.deviceName, equals('Test')); // unchanged
      expect(updated.avgHr, equals(140));
      expect(updated.minHr, equals(80));
      expect(updated.maxHr, equals(180));
      expect(updated.endTime, isNotNull);
    });

    test('equality works correctly', () {
      final startTime = DateTime(2024, 1, 1, 10, 0, 0);
      final session1 = WorkoutSession(
        id: 1,
        startTime: startTime,
        deviceName: 'Test',
      );
      final session2 = WorkoutSession(
        id: 1,
        startTime: startTime,
        deviceName: 'Test',
      );
      final session3 = WorkoutSession(
        id: 2,
        startTime: startTime,
        deviceName: 'Test',
      );

      expect(session1 == session2, isTrue);
      expect(session1 == session3, isFalse);
      expect(session1.hashCode, equals(session2.hashCode));
    });

    test('toString returns expected format', () {
      final session = WorkoutSession(
        id: 1,
        startTime: DateTime(2024, 1, 1),
        deviceName: 'Polar H10',
        avgHr: 140,
      );

      final str = session.toString();

      expect(str, contains('WorkoutSession'));
      expect(str, contains('id: 1'));
      expect(str, contains('deviceName: Polar H10'));
      expect(str, contains('avgHr: 140'));
    });
  });

  group('SessionState', () {
    test('creates inactive state by default', () {
      const state = SessionState();

      expect(state.currentSessionId, isNull);
      expect(state.startTime, isNull);
      expect(state.duration, equals(Duration.zero));
      expect(state.avgHr, isNull);
      expect(state.minHr, isNull);
      expect(state.maxHr, isNull);
      expect(state.readingsCount, equals(0));
    });

    test('factory inactive() creates inactive state', () {
      final state = SessionState.inactive();

      expect(state.isActive, isFalse);
      expect(state.currentSessionId, isNull);
    });

    test('isActive returns true when session id is set', () {
      const state = SessionState(currentSessionId: 1);

      expect(state.isActive, isTrue);
    });

    test('isActive returns false when session id is null', () {
      const state = SessionState();

      expect(state.isActive, isFalse);
    });

    test('copyWith updates specified fields', () {
      const state = SessionState();

      final updated = state.copyWith(
        currentSessionId: 5,
        startTime: DateTime(2024, 1, 1),
        duration: const Duration(minutes: 15),
        avgHr: 120,
        minHr: 70,
        maxHr: 160,
        readingsCount: 100,
      );

      expect(updated.currentSessionId, equals(5));
      expect(updated.startTime, equals(DateTime(2024, 1, 1)));
      expect(updated.duration, equals(const Duration(minutes: 15)));
      expect(updated.avgHr, equals(120));
      expect(updated.minHr, equals(70));
      expect(updated.maxHr, equals(160));
      expect(updated.readingsCount, equals(100));
    });

    test('copyWith preserves unchanged fields', () {
      const state = SessionState(currentSessionId: 1, readingsCount: 50);

      final updated = state.copyWith(avgHr: 100);

      expect(updated.currentSessionId, equals(1));
      expect(updated.readingsCount, equals(50));
      expect(updated.avgHr, equals(100));
    });

    test('equality works correctly', () {
      const state1 = SessionState(currentSessionId: 1, readingsCount: 10);
      const state2 = SessionState(currentSessionId: 1, readingsCount: 10);
      const state3 = SessionState(currentSessionId: 2, readingsCount: 10);

      expect(state1 == state2, isTrue);
      expect(state1 == state3, isFalse);
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('toString returns expected format', () {
      const state = SessionState(
        currentSessionId: 5,
        avgHr: 120,
        readingsCount: 100,
      );

      final str = state.toString();

      expect(str, contains('SessionState'));
      expect(str, contains('currentSessionId: 5'));
      expect(str, contains('avgHr: 120'));
      expect(str, contains('readingsCount: 100'));
    });
  });

  group('AppSettings', () {
    test('creates settings with default values', () {
      const settings = AppSettings();

      expect(settings.age, equals(defaultAge));
      expect(settings.chartWindowSeconds, equals(defaultChartWindowSeconds));
    });

    test('creates settings with custom values', () {
      const settings = AppSettings(age: 40, chartWindowSeconds: 60);

      expect(settings.age, equals(40));
      expect(settings.chartWindowSeconds, equals(60));
    });

    test('copyWith updates specified fields', () {
      const settings = AppSettings(age: 30);

      final updated = settings.copyWith(age: 45);

      expect(updated.age, equals(45));
      expect(updated.chartWindowSeconds, equals(defaultChartWindowSeconds));
    });

    test('copyWith preserves unchanged fields', () {
      const settings = AppSettings(age: 30, chartWindowSeconds: 60);

      final updated = settings.copyWith(chartWindowSeconds: 90);

      expect(updated.age, equals(30));
      expect(updated.chartWindowSeconds, equals(90));
    });

    test('equality works correctly', () {
      const settings1 = AppSettings(age: 30, chartWindowSeconds: 45);
      const settings2 = AppSettings(age: 30, chartWindowSeconds: 45);
      const settings3 = AppSettings(age: 40, chartWindowSeconds: 45);

      expect(settings1 == settings2, isTrue);
      expect(settings1 == settings3, isFalse);
      expect(settings1.hashCode, equals(settings2.hashCode));
    });

    test('toString returns expected format', () {
      const settings = AppSettings(age: 35, chartWindowSeconds: 60);

      final str = settings.toString();

      expect(str, contains('AppSettings'));
      expect(str, contains('age: 35'));
      expect(str, contains('chartWindowSeconds: 60'));
    });
  });

  group('HeartRateData', () {
    test('creates data with required fields', () {
      const data = HeartRateData(bpm: 120, zone: HeartRateZone.zone2);

      expect(data.bpm, equals(120));
      expect(data.zone, equals(HeartRateZone.zone2));
    });

    test('equality works correctly', () {
      const data1 = HeartRateData(bpm: 140, zone: HeartRateZone.zone3);
      const data2 = HeartRateData(bpm: 140, zone: HeartRateZone.zone3);
      const data3 = HeartRateData(bpm: 140, zone: HeartRateZone.zone4);
      const data4 = HeartRateData(bpm: 150, zone: HeartRateZone.zone3);

      expect(data1 == data2, isTrue);
      expect(data1 == data3, isFalse);
      expect(data1 == data4, isFalse);
      expect(data1.hashCode, equals(data2.hashCode));
    });

    test('toString returns expected format', () {
      const data = HeartRateData(bpm: 160, zone: HeartRateZone.zone4);

      final str = data.toString();

      expect(str, contains('HeartRateData'));
      expect(str, contains('bpm: 160'));
      expect(str, contains('zone: HeartRateZone.zone4'));
    });
  });

  group('ScannedDevice', () {
    test('creates device with required fields', () {
      const device = ScannedDevice(id: 'abc123', name: 'Polar H10', rssi: -60);

      expect(device.id, equals('abc123'));
      expect(device.name, equals('Polar H10'));
      expect(device.rssi, equals(-60));
      expect(device.isDemo, isFalse);
    });

    test('creates device with isDemo flag', () {
      const device = ScannedDevice(
        id: 'test',
        name: 'Test',
        rssi: -50,
        isDemo: true,
      );

      expect(device.isDemo, isTrue);
    });

    test('demoMode factory creates correct demo device', () {
      final device = ScannedDevice.demoMode();

      expect(device.id, equals('DEMO_MODE_DEVICE'));
      expect(device.name, equals('Demo Mode'));
      expect(device.rssi, equals(-30));
      expect(device.isDemo, isTrue);
    });

    test('equality works correctly', () {
      const device1 = ScannedDevice(id: 'abc', name: 'Device', rssi: -50);
      const device2 = ScannedDevice(id: 'abc', name: 'Device', rssi: -50);
      const device3 = ScannedDevice(id: 'xyz', name: 'Device', rssi: -50);

      expect(device1 == device2, isTrue);
      expect(device1 == device3, isFalse);
      expect(device1.hashCode, equals(device2.hashCode));
    });

    test('equality considers rssi', () {
      const device1 = ScannedDevice(id: 'abc', name: 'Device', rssi: -50);
      const device2 = ScannedDevice(id: 'abc', name: 'Device', rssi: -60);

      expect(device1 == device2, isFalse);
    });

    test('equality considers isDemo flag', () {
      const device1 = ScannedDevice(
        id: 'abc',
        name: 'Device',
        rssi: -50,
        isDemo: false,
      );
      const device2 = ScannedDevice(
        id: 'abc',
        name: 'Device',
        rssi: -50,
        isDemo: true,
      );

      expect(device1 == device2, isFalse);
    });

    test('toString returns expected format', () {
      const device = ScannedDevice(
        id: 'test123',
        name: 'Polar H10',
        rssi: -55,
        isDemo: false,
      );

      final str = device.toString();

      expect(str, contains('ScannedDevice'));
      expect(str, contains('id: test123'));
      expect(str, contains('name: Polar H10'));
      expect(str, contains('rssi: -55'));
      expect(str, contains('isDemo: false'));
    });
  });
}
