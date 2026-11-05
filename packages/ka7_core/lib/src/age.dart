/// How long ago a video was posted, as YouTube says it.
enum AgeUnit { day, week, month, year }

/// [AgeUnit.day] with 0 count: today.
typedef Age = ({AgeUnit unit, int count});

/// Rounded down, like YouTube's « il y a 1 an »: dates from lists are only
/// approximate anyway.
Age ageOf(DateTime published, DateTime now) {
  final days = now.difference(published).inDays;
  return switch (days) {
    < 1 => (unit: AgeUnit.day, count: 0),
    < 7 => (unit: AgeUnit.day, count: days),
    < 30 => (unit: AgeUnit.week, count: days ~/ 7),
    < 365 => (unit: AgeUnit.month, count: days ~/ 30),
    _ => (unit: AgeUnit.year, count: days ~/ 365),
  };
}
