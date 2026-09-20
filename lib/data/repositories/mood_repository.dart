import 'package:mind_care_app/data/local/hive_service.dart';
import 'package:mind_care_app/data/models/mood_entry.dart';

abstract class MoodRepository {
  Future<void> saveMoodEntry(MoodEntry entry);
  Future<List<MoodEntry>> getLast7Days();
  Future<MoodEntry?> getTodayEntry();
}

class HiveMoodRepository implements MoodRepository {
  @override
  Future<void> saveMoodEntry(MoodEntry entry) async {
    await HiveService.moodEntries.put(entry.id, entry);
  }

  @override
  Future<List<MoodEntry>> getLast7Days() async {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    final entries = HiveService.moodEntries.values
        .where((e) => !e.timestamp.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return entries;
  }

  @override
  Future<MoodEntry?> getTodayEntry() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (final entry in HiveService.moodEntries.values) {
      final entryDate = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      if (entryDate == todayDate) return entry;
    }
    return null;
  }
}
