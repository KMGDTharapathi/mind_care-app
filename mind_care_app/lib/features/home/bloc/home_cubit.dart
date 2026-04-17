import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_care_app/data/local/hive_service.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import 'package:mind_care_app/data/models/mood_entry.dart';

// ── State ────────────────────────────────────────────────────────────────────

class HomeState {
  final int streakCount;
  final MoodEntry? todayMoodEntry;
  final bool isLoading;

  const HomeState({
    this.streakCount = 0,
    this.todayMoodEntry,
    this.isLoading = false,
  });

  HomeState copyWith({
    int? streakCount,
    MoodEntry? todayMoodEntry,
    bool clearTodayMoodEntry = false,
    bool? isLoading,
  }) {
    return HomeState(
      streakCount: streakCount ?? this.streakCount,
      todayMoodEntry: clearTodayMoodEntry
          ? null
          : (todayMoodEntry ?? this.todayMoodEntry),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ── Cubit ────────────────────────────────────────────────────────────────────

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true));

    try {
      final streak = await _calculateStreak();
      final todayEntry = _getTodayMoodEntry();

      emit(HomeState(
        streakCount: streak,
        todayMoodEntry: todayEntry,
        isLoading: false,
      ));
    } catch (e) {
      // Emit non-loading state even on error so UI doesn't stay blank
      emit(HomeState(
        streakCount: 1,
        todayMoodEntry: null,
        isLoading: false,
      ));
    }
  }

  /// Streak logic (from design.md):
  /// - lastActiveDate == today  → streak unchanged
  /// - lastActiveDate == yesterday → streak + 1, update lastActiveDate
  /// - otherwise → streak resets to 1, update lastActiveDate
  Future<int> _calculateStreak() async {
    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    final lastActiveDateStr = await PreferencesService.getLastActiveDate();
    final currentStreak = await PreferencesService.getStreakCount();

    int newStreak;

    if (lastActiveDateStr == null) {
      // First launch
      newStreak = 1;
      await PreferencesService.setLastActiveDate(_formatDate(today));
      await PreferencesService.setStreakCount(newStreak);
    } else {
      final lastActiveDate = DateTime.parse(lastActiveDateStr);

      if (_dateOnly(lastActiveDate) == today) {
        // Already recorded today — no change
        newStreak = currentStreak == 0 ? 1 : currentStreak;
      } else if (_dateOnly(lastActiveDate) == yesterday) {
        // Consecutive day — increment
        newStreak = currentStreak + 1;
        await PreferencesService.setLastActiveDate(_formatDate(today));
        await PreferencesService.setStreakCount(newStreak);
      } else {
        // Gap — reset
        newStreak = 1;
        await PreferencesService.setLastActiveDate(_formatDate(today));
        await PreferencesService.setStreakCount(newStreak);
      }
    }

    return newStreak;
  }

  MoodEntry? _getTodayMoodEntry() {
    try {
      final today = _dateOnly(DateTime.now());
      final box = HiveService.moodEntries;
      for (final entry in box.values) {
        if (_dateOnly(entry.timestamp) == today) {
          return entry;
        }
      }
    } catch (_) {}
    return null;
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _formatDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
