import 'package:flutter_test/flutter_test.dart';
import 'package:todow/domain/date_labels.dart';

void main() {
  group('relativeDueLabel', () {
    final now = DateTime(2026, 10, 1, 12, 0); // Oct 1, 2026

    test('returns Today without time if no time exists', () {
      final due = DateTime(2026, 10, 1);
      expect(relativeDueLabel(due, now: now), 'Today');
    });

    test('returns Today with time if time exists', () {
      final due = DateTime(2026, 10, 1, 15, 0);
      expect(relativeDueLabel(due, now: now), 'Today · 3 PM');
    });

    test('returns Tomorrow', () {
      final due = DateTime(2026, 10, 2);
      expect(relativeDueLabel(due, now: now), 'Tomorrow');
    });

    test('returns weekday for next 7 days', () {
      final due = DateTime(2026, 10, 4); // Sunday
      expect(relativeDueLabel(due, now: now), 'Sunday');
    });

    test('returns Overdue for past dates', () {
      final due = DateTime(2026, 9, 30);
      expect(relativeDueLabel(due, now: now), 'Overdue · Sep 30');
    });
  });
}
