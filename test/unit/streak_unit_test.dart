import 'package:flutter_test/flutter_test.dart';

// ── Streak logic (same as in streak_property_test.dart) ───────────────────────

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

String _formatDate(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';

int calculateStreak({
  required int currentStreak,
  required String? lastActiveDateStr,
  required DateTime today,
}) {
  final todayDate = _dateOnly(today);
  final yesterday = todayDate.subtract(const Duration(days: 1));

  if (lastActiveDateStr == null) {
    return 1;
  }

  final lastActiveDate = _dateOnly(DateTime.parse(lastActiveDateStr));

  if (lastActiveDate == todayDate) {
    return currentStreak == 0 ? 1 : currentStreak;
  } else if (lastActiveDate == yesterday) {
    return currentStreak + 1;
  } else {
    return 1;
  }
}

void main() {
  final today = DateTime(2024, 6, 15);

  group('Streak unit tests', () {
    test('gap of 3 days resets streak to 1', () {
      final lastActive = _formatDate(today.subtract(const Duration(days: 3)));
      final result = calculateStreak(
        currentStreak: 7,
        lastActiveDateStr: lastActive,
        today: today,
      );
      expect(result, equals(1));
    });

    test('same-day activity does not change streak', () {
      final lastActive = _formatDate(today);
      final result = calculateStreak(
        currentStreak: 5,
        lastActiveDateStr: lastActive,
        today: today,
      );
      expect(result, equals(5));
    });

    test('same-day with streak 0 returns 1', () {
      final lastActive = _formatDate(today);
      final result = calculateStreak(
        currentStreak: 0,
        lastActiveDateStr: lastActive,
        today: today,
      );
      expect(result, equals(1));
    });

    test('first launch (no lastActiveDate) starts streak at 1', () {
      final result = calculateStreak(
        currentStreak: 0,
        lastActiveDateStr: null,
        today: today,
      );
      expect(result, equals(1));
    });

    test('consecutive day increments streak by 1', () {
      final yesterday = _formatDate(today.subtract(const Duration(days: 1)));
      final result = calculateStreak(
        currentStreak: 4,
        lastActiveDateStr: yesterday,
        today: today,
      );
      expect(result, equals(5));
    });

    test('gap of 2 days resets streak to 1', () {
      final twoDaysAgo = _formatDate(today.subtract(const Duration(days: 2)));
      final result = calculateStreak(
        currentStreak: 10,
        lastActiveDateStr: twoDaysAgo,
        today: today,
      );
      expect(result, equals(1));
    });
  });
}
