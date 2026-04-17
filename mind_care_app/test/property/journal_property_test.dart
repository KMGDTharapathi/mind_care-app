// Feature: mind-care-app, Property 3: Journal entry round-trip persistence
// Feature: mind-care-app, Property 4: Journal empty-body rejection
// Feature: mind-care-app, Property 5: Journal list descending order invariant

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_care_app/data/models/journal_entry.dart';
import 'package:mind_care_app/data/repositories/journal_repository.dart';

// ── In-memory JournalRepository ───────────────────────────────────────────────

class InMemoryJournalRepository implements JournalRepository {
  final Map<String, JournalEntry> _store = {};

  @override
  Future<void> saveEntry(JournalEntry entry) async {
    // Reject whitespace-only body
    if (entry.body.trim().isEmpty) return;
    _store[entry.id] = entry;
  }

  @override
  Future<void> deleteEntry(String id) async {
    _store.remove(id);
  }

  @override
  Future<List<JournalEntry>> getAllEntries() async {
    final entries = _store.values.toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  void clear() => _store.clear();
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _randomString(Random rng, int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}

String _randomNonEmptyBody(Random rng) {
  final length = 1 + rng.nextInt(200);
  // Ensure at least one non-whitespace character
  final body = _randomString(rng, length);
  return body.isEmpty ? 'x' : body;
}

void main() {
  group('Property 3: Journal entry round-trip persistence', () {
    // Feature: mind-care-app, Property 3: Journal entry round-trip persistence
    // Validates: Requirements 5.1, 5.2
    test('saving a JournalEntry and retrieving all entries includes the saved entry', () async {
      final rng = Random(42);
      final repo = InMemoryJournalRepository();

      for (int i = 0; i < 100; i++) {
        repo.clear();

        final id = 'entry-$i';
        final title = _randomString(rng, 1 + rng.nextInt(50));
        final body = _randomNonEmptyBody(rng);
        final createdAt = DateTime(
          2024,
          1 + rng.nextInt(12),
          1 + rng.nextInt(28),
          rng.nextInt(24),
          rng.nextInt(60),
        );
        final updatedAt = createdAt.add(Duration(minutes: rng.nextInt(60)));

        final entry = JournalEntry(
          id: id,
          title: title,
          body: body,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

        await repo.saveEntry(entry);
        final entries = await repo.getAllEntries();

        expect(entries.any((e) => e.id == id), isTrue,
            reason: 'Iteration $i: saved entry should be in getAllEntries');

        final found = entries.firstWhere((e) => e.id == id);
        expect(found.title, equals(title),
            reason: 'Iteration $i: title should match');
        expect(found.body, equals(body),
            reason: 'Iteration $i: body should match');
        expect(found.createdAt, equals(createdAt),
            reason: 'Iteration $i: createdAt should match');
        expect(found.updatedAt, equals(updatedAt),
            reason: 'Iteration $i: updatedAt should match');
      }
    });
  });

  group('Property 4: Journal empty-body rejection', () {
    // Feature: mind-care-app, Property 4: Journal empty-body rejection
    // Validates: Requirements 5.6
    test('entries with whitespace-only body are not stored', () async {
      final rng = Random(77);
      final repo = InMemoryJournalRepository();

      // Whitespace characters to use
      const whitespaceChars = [' ', '\t', '\n', '\r'];

      for (int i = 0; i < 100; i++) {
        repo.clear();

        final length = 1 + rng.nextInt(20);
        final body = List.generate(
          length,
          (_) => whitespaceChars[rng.nextInt(whitespaceChars.length)],
        ).join();

        final entry = JournalEntry(
          id: 'ws-$i',
          title: 'Test',
          body: body,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repo.saveEntry(entry);
        final entries = await repo.getAllEntries();

        expect(entries.any((e) => e.id == 'ws-$i'), isFalse,
            reason:
                'Iteration $i: whitespace-only body entry should be rejected');
      }
    });
  });

  group('Property 5: Journal list descending order invariant', () {
    // Feature: mind-care-app, Property 5: Journal list descending order invariant
    // Validates: Requirements 5.3
    test('getAllEntries returns entries sorted by createdAt descending', () async {
      final rng = Random(13);
      final repo = InMemoryJournalRepository();

      for (int i = 0; i < 100; i++) {
        repo.clear();

        final n = 2 + rng.nextInt(9); // 2–10 entries
        final baseTime = DateTime(2024, 1, 1);

        // Generate distinct timestamps by using different offsets
        final offsets = List.generate(n, (idx) => idx * 60 + rng.nextInt(30));
        offsets.shuffle(rng);

        for (int j = 0; j < n; j++) {
          final createdAt = baseTime.add(Duration(minutes: offsets[j]));
          final entry = JournalEntry(
            id: 'e-$i-$j',
            title: 'Title $j',
            body: 'Body content $j',
            createdAt: createdAt,
            updatedAt: createdAt,
          );
          await repo.saveEntry(entry);
        }

        final entries = await repo.getAllEntries();

        expect(entries.length, equals(n),
            reason: 'Iteration $i: should have $n entries');

        for (int k = 0; k < entries.length - 1; k++) {
          expect(
            entries[k].createdAt.isAfter(entries[k + 1].createdAt) ||
                entries[k].createdAt.isAtSameMomentAs(entries[k + 1].createdAt),
            isTrue,
            reason:
                'Iteration $i: entry[$k] createdAt should be >= entry[${k + 1}] createdAt',
          );
        }
      }
    });
  });
}
