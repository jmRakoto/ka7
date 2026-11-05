import 'package:ka7_core/ka7_core.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 11, 5, 12);

Age _ago(Duration span) => ageOf(_now.subtract(span), _now);

void main() {
  test('today, then days', () {
    expect(_ago(const Duration(hours: 5)), (unit: AgeUnit.day, count: 0));
    expect(_ago(const Duration(days: 3)), (unit: AgeUnit.day, count: 3));
  });

  test('weeks from 7 days', () {
    expect(_ago(const Duration(days: 7)), (unit: AgeUnit.week, count: 1));
    expect(_ago(const Duration(days: 20)), (unit: AgeUnit.week, count: 2));
  });

  test('months from 30 days', () {
    expect(_ago(const Duration(days: 31)), (unit: AgeUnit.month, count: 1));
    expect(_ago(const Duration(days: 300)), (unit: AgeUnit.month, count: 10));
  });

  test('years from 365 days', () {
    expect(_ago(const Duration(days: 365)), (unit: AgeUnit.year, count: 1));
    expect(_ago(const Duration(days: 365 * 6 + 30)), (
      unit: AgeUnit.year,
      count: 6,
    ));
  });

  test('a date ahead (clock drift) reads as today', () {
    expect(ageOf(_now.add(const Duration(days: 2)), _now), (
      unit: AgeUnit.day,
      count: 0,
    ));
  });
}
