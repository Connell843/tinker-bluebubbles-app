import 'package:bluebubbles/helpers/types/helpers/schedule_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextTimeOfDay', () {
    test('is today while the time is still ahead', () {
      expect(nextTimeOfDay(9, 13, from: DateTime(2026, 11, 26, 8, 0)), DateTime(2026, 11, 26, 9, 13));
    });

    test('is tomorrow once the time has passed', () {
      expect(nextTimeOfDay(9, 13, from: DateTime(2026, 11, 26, 14, 30)), DateTime(2026, 11, 27, 9, 13));
    });

    test('is tomorrow at exactly the time, so it is never scheduled for now', () {
      expect(nextTimeOfDay(9, 13, from: DateTime(2026, 11, 26, 9, 13)), DateTime(2026, 11, 27, 9, 13));
    });

    test('is today one second before the time', () {
      expect(nextTimeOfDay(9, 13, from: DateTime(2026, 11, 26, 9, 12, 59)), DateTime(2026, 11, 26, 9, 13));
    });

    test('rolls over the end of a month and a year', () {
      expect(nextTimeOfDay(9, 13, from: DateTime(2026, 11, 30, 22, 0)), DateTime(2026, 12, 1, 9, 13));
      expect(nextTimeOfDay(9, 13, from: DateTime(2026, 12, 31, 22, 0)), DateTime(2027, 1, 1, 9, 13));
    });
  });

  group('SchedulePreset', () {
    final now = DateTime(2026, 11, 26, 10, 30);

    test('hour presets count from the given time', () {
      expect(SchedulePreset.oneHour.resolve(now), DateTime(2026, 11, 26, 11, 30));
      expect(SchedulePreset.twoHours.resolve(now), DateTime(2026, 11, 26, 12, 30));
      expect(SchedulePreset.threeHours.resolve(now), DateTime(2026, 11, 26, 13, 30));
    });

    test('next morning is the next 9:13 AM', () {
      expect(SchedulePreset.nextMorning.resolve(now), DateTime(2026, 11, 27, 9, 13));
      expect(SchedulePreset.nextMorning.resolve(DateTime(2026, 11, 26, 6, 0)), DateTime(2026, 11, 26, 9, 13));
    });

    test('every preset lands in the future', () {
      for (final preset in SchedulePreset.values) {
        expect(preset.resolve(now).isAfter(now), isTrue, reason: preset.label);
      }
    });
  });
}
