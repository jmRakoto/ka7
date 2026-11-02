import 'package:flutter_test/flutter_test.dart';
import 'package:ka7/features/preview/durations.dart';

void main() {
  test('rounds a total to the minute', () {
    expect(span(const Duration(minutes: 13, seconds: 20)), '13 min');
    expect(span(const Duration(hours: 2, minutes: 7)), '2 h 07');
  });

  test('never shows 0 min for a short video', () {
    expect(span(const Duration(seconds: 19)), '< 1 min');
  });

  test('shows nothing to download as 0 min', () {
    expect(span(Duration.zero), '0 min');
  });
}
