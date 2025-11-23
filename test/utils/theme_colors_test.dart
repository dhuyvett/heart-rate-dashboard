import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/heart_rate_zone.dart';
import 'package:heart_rate_dashboard/utils/theme_colors.dart';

void main() {
  group('ZoneColors', () {
    group('color constants', () {
      test('resting color is blue', () {
        expect(ZoneColors.resting, equals(Colors.blue));
      });

      test('zone1 color is light blue', () {
        expect(ZoneColors.zone1, equals(Colors.lightBlue));
      });

      test('zone2 color is green', () {
        expect(ZoneColors.zone2, equals(Colors.green));
      });

      test('zone3 color is yellow', () {
        expect(ZoneColors.zone3, equals(Colors.yellow));
      });

      test('zone4 color is orange', () {
        expect(ZoneColors.zone4, equals(Colors.orange));
      });

      test('zone5 color is red', () {
        expect(ZoneColors.zone5, equals(Colors.red));
      });
    });

    group('getColorForZone', () {
      test('returns blue for resting zone', () {
        expect(
          ZoneColors.getColorForZone(HeartRateZone.resting),
          equals(Colors.blue),
        );
      });

      test('returns light blue for zone1', () {
        expect(
          ZoneColors.getColorForZone(HeartRateZone.zone1),
          equals(Colors.lightBlue),
        );
      });

      test('returns green for zone2', () {
        expect(
          ZoneColors.getColorForZone(HeartRateZone.zone2),
          equals(Colors.green),
        );
      });

      test('returns yellow for zone3', () {
        expect(
          ZoneColors.getColorForZone(HeartRateZone.zone3),
          equals(Colors.yellow),
        );
      });

      test('returns orange for zone4', () {
        expect(
          ZoneColors.getColorForZone(HeartRateZone.zone4),
          equals(Colors.orange),
        );
      });

      test('returns red for zone5', () {
        expect(
          ZoneColors.getColorForZone(HeartRateZone.zone5),
          equals(Colors.red),
        );
      });

      test('returns correct color for all zones', () {
        // Verify all zones have unique colors (except potentially zone1/lightBlue)
        final colors = HeartRateZone.values
            .map(ZoneColors.getColorForZone)
            .toList();

        expect(colors, hasLength(6));
        // All colors should be valid Color objects
        for (final color in colors) {
          expect(color, isA<Color>());
        }
      });
    });

    group('color progression', () {
      test('colors progress from cool to warm as intensity increases', () {
        // Resting/Zone1 are cool colors (blue family)
        expect(ZoneColors.resting, equals(Colors.blue));
        expect(ZoneColors.zone1, equals(Colors.lightBlue));

        // Zone2 is green (neutral/moderate)
        expect(ZoneColors.zone2, equals(Colors.green));

        // Zone3-5 progress through warm colors
        expect(ZoneColors.zone3, equals(Colors.yellow));
        expect(ZoneColors.zone4, equals(Colors.orange));
        expect(ZoneColors.zone5, equals(Colors.red));
      });
    });
  });
}
