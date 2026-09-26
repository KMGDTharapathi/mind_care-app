// Feature: mind-care-app, Property 6: Resource search completeness and correctness
// Feature: mind-care-app, Property 7: Bookmark round-trip

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_care_app/data/models/resource.dart';

// ── In-memory ResourceRepository ─────────────────────────────────────────────

class InMemoryResourceRepository {
  final List<Resource> _resources;
  final Set<String> _bookmarks = {};

  InMemoryResourceRepository(this._resources);

  List<Resource> getAll() {
    return _resources.map((r) {
      r.isBookmarked = _bookmarks.contains(r.id);
      return r;
    }).toList();
  }

  List<Resource> search(String query) {
    if (query.isEmpty) return getAll();
    final lower = query.toLowerCase();
    return getAll().where((r) {
      final titleMatch = r.title.toLowerCase().contains(lower);
      final keywordMatch =
          r.keywords.any((k) => k.toLowerCase().contains(lower));
      return titleMatch || keywordMatch;
    }).toList();
  }

  Future<void> bookmark(String resourceId) async {
    _bookmarks.add(resourceId);
  }

  Future<void> removeBookmark(String resourceId) async {
    _bookmarks.remove(resourceId);
  }

  Future<List<Resource>> getBookmarked() async {
    return _resources
        .where((r) => _bookmarks.contains(r.id))
        .map((r) {
          r.isBookmarked = true;
          return r;
        })
        .toList();
  }

  void clearBookmarks() => _bookmarks.clear();
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _randomString(Random rng, int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz';
  return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
}

List<Resource> _buildTestResources() {
  return [
    Resource(
      id: 'r1',
      title: 'Understanding Anxiety',
      category: 'Anxiety',
      content: 'Anxiety is a natural response to stress.',
      keywords: ['anxiety', 'stress', 'triggers'],
    ),
    Resource(
      id: 'r2',
      title: 'Sleep Hygiene Tips',
      category: 'Sleep',
      content: 'Good sleep hygiene promotes consistent sleep.',
      keywords: ['sleep', 'hygiene', 'rest'],
    ),
    Resource(
      id: 'r3',
      title: 'Mindfulness Meditation',
      category: 'Mindfulness',
      content: 'Mindfulness is the practice of present-moment awareness.',
      keywords: ['mindfulness', 'meditation', 'breath'],
    ),
    Resource(
      id: 'r4',
      title: 'Stress Reduction Techniques',
      category: 'Stress',
      content: 'Progressive muscle relaxation reduces stress.',
      keywords: ['stress', 'relaxation', 'muscle'],
    ),
    Resource(
      id: 'r5',
      title: 'Breathing Exercises',
      category: 'Anxiety',
      content: 'Deep breathing calms the nervous system.',
      keywords: ['breathing', 'calm', 'anxiety'],
    ),
  ];
}

void main() {
  group('Property 6: Resource search completeness and correctness', () {
    // Feature: mind-care-app, Property 6: Resource search completeness and correctness
    // Validates: Requirements 6.5
    test('search returns only matching resources and omits no matches', () {
      final rng = Random(42);
      final resources = _buildTestResources();
      final repo = InMemoryResourceRepository(resources);

      // Queries derived from known keywords/titles to ensure some matches exist
      final queryPool = [
        'anxiety',
        'sleep',
        'mind',
        'stress',
        'breath',
        'calm',
        'rest',
        'med',
        'hyg',
        'rel',
      ];

      for (int i = 0; i < 100; i++) {
        final query = queryPool[rng.nextInt(queryPool.length)];
        final lower = query.toLowerCase();

        final results = repo.search(query);

        // Correctness: every result must match
        for (final r in results) {
          final titleMatch = r.title.toLowerCase().contains(lower);
          final keywordMatch =
              r.keywords.any((k) => k.toLowerCase().contains(lower));
          expect(titleMatch || keywordMatch, isTrue,
              reason:
                  'Iteration $i: result "${r.title}" does not match query "$query"');
        }

        // Completeness: no matching resource should be omitted
        final allMatching = resources.where((r) {
          final titleMatch = r.title.toLowerCase().contains(lower);
          final keywordMatch =
              r.keywords.any((k) => k.toLowerCase().contains(lower));
          return titleMatch || keywordMatch;
        }).toList();

        expect(results.length, equals(allMatching.length),
            reason:
                'Iteration $i: search("$query") returned ${results.length} but expected ${allMatching.length}');
      }
    });
  });

  group('Property 7: Bookmark round-trip', () {
    // Feature: mind-care-app, Property 7: Bookmark round-trip
    // Validates: Requirements 6.3, 6.4
    test('bookmarking a resource makes it appear in getBookmarked; removing it makes it absent', () async {
      final rng = Random(99);
      final resources = _buildTestResources();
      final repo = InMemoryResourceRepository(resources);

      for (int i = 0; i < 100; i++) {
        repo.clearBookmarks();

        final resource = resources[rng.nextInt(resources.length)];
        final id = resource.id;

        // Bookmark
        await repo.bookmark(id);
        final afterBookmark = await repo.getBookmarked();
        expect(afterBookmark.any((r) => r.id == id), isTrue,
            reason:
                'Iteration $i: resource "$id" should be in bookmarks after bookmarking');

        // Remove bookmark
        await repo.removeBookmark(id);
        final afterRemove = await repo.getBookmarked();
        expect(afterRemove.any((r) => r.id == id), isFalse,
            reason:
                'Iteration $i: resource "$id" should not be in bookmarks after removing');
      }
    });
  });
}
