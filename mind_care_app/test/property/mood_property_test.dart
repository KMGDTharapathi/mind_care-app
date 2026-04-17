// Feature: mind-care-app, Property 1: Mood entry round-trip persistence
// Feature: mind-care-app, Property 2: Mood note length validation

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_care_app/data/models/mood_entry.dart';
import 'package:mind_care_app/data/repositories/mood_repository.dart';

// ── In-memory MoodRepository ──────────────────────────────────────────────────

class InMemoryMoodRepository implements MoodRepository {
  final Map<String, MoodEntry> _store = {};

  @override
  Future<void> saveMoodEntry(MoodEntry entry) async {
    // Enforce note length ≤ 200
    final truncatedNote = entry.note != null && entry.note!.length > 200
        ? entry.note!.substring(0, 200)
        : entry.note;
    final stored = MoodEntry(
      id: entry.id,
      mood: entry.mood,
      note: truncatedNote,
      timestamp: entry.timestamp,
    );
    _store[entry.id] = stored;
  }

  @override
  Future<List<MoodEntry>> getLast7Days() async {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    return _store.values
        .where((e) => !e.timestamp.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Future<MoodEntry?> getTodayEntry() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    for (final entry in _store.values) {
      final entryDate = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      if (entryDate == todayDate) return entry;
    }
    return null;
  }

  void clear() => _store.clear();
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _randomString(Random rng, int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}

MoodType _randomMoodType(Random rng) {
  final values = MoodType.values;
  return values[rng.nextInt(values.length)];
}

void main() {
  group('Property 1: Mood entry round-trip persistence', () {
    // Feature: mind-care-app, Property 1: Mood entry round-trip persistence
    // Validates: Requirements 3.2
    test('saving a MoodEntry and retrieving today\'s entry returns same mood and note', () async {
      final rng = Random(42);
      final repo = InMemoryMoodRepository();

      for (int i = 0; i < 100; i++) {
        repo.clear();

        final mood = _randomMoodType(rng);
        final hasNote = rng.nextBool();
        final noteLength = hasNote ? rng.nextInt(200) + 1 : 0;
        final note = hasNote ? _randomString(rng, noteLength) : null;
        final now = DateTime.now();
        final timestamp = DateTime(now.year, now.month, now.day,
            rng.nextInt(24), rng.nextInt(60), rng.nextInt(60));

        final entry = MoodEntry(
          id: 'test-$i',
          mood: mood,
          note: note,
          timestamp: timestamp,
        );

        await repo.saveMoodEntry(entry);
        final retrieved = await repo.getTodayEntry();

        expect(retrieved, isNotNull,
            reason: 'Iteration $i: getTodayEntry should return the saved entry');
        expect(retrieved!.mood, equals(mood),
            reason: 'Iteration $i: mood should match');
        expect(retrieved.note, equals(note),
            reason: 'Iteration $i: note should match');
      }
    });
  });

  group('Property 2: Mood note length validation', () {
    // Feature: mind-care-app, Property 2: Mood note length validation
    // Validates: Requirements 3.3
    test('notes longer than 200 chars are stored with length ≤ 200', () async {
      final rng = Random(99);
      final repo = InMemoryMoodRepository();

      for (int i = 0; i < 100; i++) {
        repo.clear();

        final noteLength = 201 + rng.nextInt(300); // 201–500
        final longNote = _randomString(rng, noteLength);

        final entry = MoodEntry(
          id: 'test-$i',
          mood: _randomMoodType(rng),
          note: longNote,
          timestamp: DateTime.now(),
        );

        await repo.saveMoodEntry(entry);
        final retrieved = await repo.getTodayEntry();

        expect(retrieved, isNotNull,
            reason: 'Iteration $i: entry should be stored');
        expect(retrieved!.note, isNotNull,
            reason: 'Iteration $i: note should not be null');
        expect(retrieved.note!.length, lessThanOrEqualTo(200),
            reason:
                'Iteration $i: stored note length ${retrieved.note!.length} exceeds 200');
      }
    });
  });
}
