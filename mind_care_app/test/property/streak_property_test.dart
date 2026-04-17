// Feature: mind-care-app, Property 8: Streak increment on consecutive days

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

// ── Streak logic (extracted from HomeCubit) ───────────────────────────────────

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

String _formatDate(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';

/// Calculates the new streak given the current streak and last active date.
/// Returns the new streak value.
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
  group('Property 8: Streak increment on consecutive days', () {
    // Feature: mind-care-app, Property 8: Streak increment on consecutive days
    // Validates: Requirements 2.2
    test('when lastActiveDate is yesterday, new streak equals old streak + 1', () {
      final rng = Random(42);

      for (int i = 0; i < 100; i++) {
        final currentStreak = 1 + rng.nextInt(100); // 1–100
        final today = DateTime(2024, 6, 15); // fixed reference date
        final yesterday = today.subtract(const Duration(days: 1));
        final lastActiveDateStr = _formatDate(yesterday);

        final newStreak = calculateStreak(
          currentStreak: currentStreak,
          lastActiveDateStr: lastActiveDateStr,
          today: today,
        );

        expect(newStreak, equals(currentStreak + 1),
            reason:
                'Iteration $i: streak $currentStreak with lastActive=yesterday should become ${currentStreak + 1}');
      }
    });
  });
}
