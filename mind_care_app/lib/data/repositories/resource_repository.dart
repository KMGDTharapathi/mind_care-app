import '../local/hive_service.dart';
import '../models/resource.dart';

final List<Resource> _seedResources = [
  // Anxiety
  Resource(
    id: 'anxiety-1',
    title: 'Understanding Anxiety',
    category: 'Anxiety',
    content:
        'Anxiety is a natural response to stress, but when it becomes overwhelming it can interfere with daily life. '
        'Learning to recognize your anxiety triggers is the first step toward managing them. '
        'Simple techniques like deep breathing and grounding exercises can help reduce anxious feelings in the moment.',
    keywords: ['anxiety', 'stress', 'triggers', 'breathing', 'grounding'],
  ),
  Resource(
    id: 'anxiety-2',
    title: '5-4-3-2-1 Grounding Technique',
    category: 'Anxiety',
    content:
        'The 5-4-3-2-1 technique uses your five senses to anchor you to the present moment during anxiety. '
        'Name 5 things you can see, 4 you can touch, 3 you can hear, 2 you can smell, and 1 you can taste. '
        'This practice interrupts anxious thought spirals and brings your focus back to the here and now.',
    keywords: ['grounding', 'anxiety', 'senses', 'mindfulness', 'present'],
  ),
  // Sleep
  Resource(
    id: 'sleep-1',
    title: 'Building a Bedtime Routine',
    category: 'Sleep',
    content:
        'A consistent bedtime routine signals to your brain that it is time to wind down and prepare for sleep. '
        'Try dimming lights, avoiding screens, and doing a calming activity like reading or light stretching 30 minutes before bed. '
        'Going to bed and waking at the same time each day strengthens your natural sleep-wake cycle.',
    keywords: ['sleep', 'routine', 'bedtime', 'insomnia', 'rest'],
  ),
  Resource(
    id: 'sleep-2',
    title: 'Sleep Hygiene Tips',
    category: 'Sleep',
    content:
        'Good sleep hygiene involves habits that promote consistent, uninterrupted sleep. '
        'Keep your bedroom cool, dark, and quiet, and reserve it primarily for sleep. '
        'Limit caffeine after noon and avoid heavy meals close to bedtime to improve sleep quality.',
    keywords: ['sleep', 'hygiene', 'caffeine', 'bedroom', 'quality'],
  ),
  // Stress
  Resource(
    id: 'stress-1',
    title: 'Progressive Muscle Relaxation',
    category: 'Stress',
    content:
        'Progressive muscle relaxation (PMR) involves tensing and then releasing muscle groups throughout your body. '
        'Starting from your feet and working upward, tense each group for 5 seconds then release for 30 seconds. '
        'Regular PMR practice reduces physical tension and lowers overall stress levels.',
    keywords: ['stress', 'relaxation', 'muscle', 'tension', 'body'],
  ),
  Resource(
    id: 'stress-2',
    title: 'Time Management for Stress Reduction',
    category: 'Stress',
    content:
        'Poor time management is a leading cause of chronic stress. '
        'Breaking large tasks into smaller steps and prioritizing using a simple to-do list can make workloads feel manageable. '
        'Scheduling short breaks throughout the day helps maintain focus and prevents burnout.',
    keywords: ['stress', 'time management', 'productivity', 'burnout', 'tasks'],
  ),
  // Mindfulness
  Resource(
    id: 'mindfulness-1',
    title: 'Introduction to Mindfulness Meditation',
    category: 'Mindfulness',
    content:
        'Mindfulness meditation is the practice of paying attention to the present moment without judgment. '
        'Start with just 5 minutes a day: sit comfortably, focus on your breath, and gently return your attention when your mind wanders. '
        'Consistent practice has been shown to reduce stress, improve focus, and enhance emotional regulation.',
    keywords: ['mindfulness', 'meditation', 'breath', 'present', 'focus'],
  ),
  Resource(
    id: 'mindfulness-2',
    title: 'Mindful Eating',
    category: 'Mindfulness',
    content:
        'Mindful eating means paying full attention to the experience of eating — the taste, texture, and smell of your food. '
        'Eating slowly without distractions helps you recognize hunger and fullness cues more accurately. '
        'This practice can improve your relationship with food and reduce stress-related overeating.',
    keywords: ['mindfulness', 'eating', 'food', 'awareness', 'habits'],
  ),
];

class ResourceRepository {
  List<Resource> getAll() {
    final bookmarks = HiveService.bookmarks;
    return _seedResources.map((r) {
      r.isBookmarked = bookmarks.containsKey(r.id);
      return r;
    }).toList();
  }

  List<Resource> search(String query) {
    if (query.isEmpty) return getAll();
    final lower = query.toLowerCase();
    return getAll().where((r) {
      final titleMatch = r.title.toLowerCase().contains(lower);
      final keywordMatch = r.keywords.any((k) => k.toLowerCase().contains(lower));
      return titleMatch || keywordMatch;
    }).toList();
  }

  Future<void> bookmark(String resourceId) async {
    await HiveService.bookmarks.put(resourceId, resourceId);
  }

  Future<void> removeBookmark(String resourceId) async {
    await HiveService.bookmarks.delete(resourceId);
  }

  Future<List<Resource>> getBookmarked() async {
    final bookmarks = HiveService.bookmarks;
    return _seedResources
        .where((r) => bookmarks.containsKey(r.id))
        .map((r) {
          r.isBookmarked = true;
          return r;
        })
        .toList();
  }
}
