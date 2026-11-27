/// The quick picks in the send sheet's Schedule tab. Each resolves to a time only when it's used, so
/// "In 1 hour" counts from the moment the message is scheduled, not from when the sheet was opened.
enum SchedulePreset {
  oneHour("In 1 hour"),
  twoHours("In 2 hours"),
  threeHours("In 3 hours"),
  nextMorning("Next 9:13 AM");

  const SchedulePreset(this.label);

  final String label;

  /// The hour and minute [nextMorning] sends at.
  static const morningHour = 9;
  static const morningMinute = 13;

  DateTime resolve([DateTime? from]) {
    final now = from ?? DateTime.now();
    return switch (this) {
      SchedulePreset.oneHour => now.add(const Duration(hours: 1)),
      SchedulePreset.twoHours => now.add(const Duration(hours: 2)),
      SchedulePreset.threeHours => now.add(const Duration(hours: 3)),
      SchedulePreset.nextMorning => nextTimeOfDay(morningHour, morningMinute, from: now),
    };
  }
}

/// The next time the clock reads [hour]:[minute] after [from]: today if that is still ahead, otherwise
/// tomorrow. Built from calendar fields rather than by adding 24 hours, so a daylight saving change
/// overnight doesn't shift it off the minute.
DateTime nextTimeOfDay(int hour, int minute, {DateTime? from}) {
  final now = from ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  if (today.isAfter(now)) return today;
  return DateTime(now.year, now.month, now.day + 1, hour, minute);
}
