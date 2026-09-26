import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/core/router/app_router.dart';

/// A wellness feature inside the app that Willow can suggest.
///
/// [id] values are shared with the AI server so a recommended feature from the
/// model can be matched to a screen here. Unknown ids are silently ignored.
class WellnessFeature {
  final String id;
  final String enLabel;
  final String siLabel;
  final IconData icon;
  final Color color;
  final String _route;

  const WellnessFeature({
    required this.id,
    required this.enLabel,
    required this.siLabel,
    required this.icon,
    required this.color,
    required String route,
  }) : _route = route;

  String label(bool isSinhala) => isSinhala ? siLabel : enLabel;

  /// Opens the feature screen for this recommendation.
  void open(BuildContext context) => context.push(_route);

  static const Map<String, WellnessFeature> all = {
    'breathing': WellnessFeature(
      id: 'breathing',
      enLabel: 'Quick breathing',
      siLabel: 'ඉක්මන් හුස්ම අභ්‍යාස',
      icon: Icons.air_rounded,
      color: Color(0xFF4DB6AC),
      route: AppRouter.breathingExercises,
    ),
    'meditation': WellnessFeature(
      id: 'meditation',
      enLabel: 'Guided meditation',
      siLabel: 'මග පෙන්වන භාවනාව',
      icon: Icons.self_improvement_outlined,
      color: Color(0xFF5BA8A0),
      route: AppRouter.meditation,
    ),
    'calmMusic': WellnessFeature(
      id: 'calmMusic',
      enLabel: 'Calm music',
      siLabel: 'සන්සුන් සංගීතය',
      icon: Icons.headset_outlined,
      color: Color(0xFF26A69A),
      route: AppRouter.calmMusic,
    ),
    'journal': WellnessFeature(
      id: 'journal',
      enLabel: 'Journaling',
      siLabel: 'දිනපොත',
      icon: Icons.menu_book_outlined,
      color: Color(0xFF7E57C2),
      route: AppRouter.journal,
    ),
    'games': WellnessFeature(
      id: 'games',
      enLabel: 'Stress-relief games',
      siLabel: 'සමනය ක්‍රීඩා',
      icon: Icons.sports_esports_outlined,
      color: Color(0xFF66BB6A),
      route: AppRouter.games,
    ),
    'painting': WellnessFeature(
      id: 'painting',
      enLabel: 'Mindful painting',
      siLabel: 'පින්තාරු කිරීම',
      icon: Icons.brush_outlined,
      color: Color(0xFFEC407A),
      route: AppRouter.painting,
    ),
    'motivational': WellnessFeature(
      id: 'motivational',
      enLabel: 'Motivational quotes',
      siLabel: 'දිරිගැන්වීම්',
      icon: Icons.emoji_events_outlined,
      color: Color(0xFFFB8C00),
      route: AppRouter.motivational,
    ),
    'moodTracker': WellnessFeature(
      id: 'moodTracker',
      enLabel: 'Mood check-in',
      siLabel: 'හැඟීම් සටහන',
      icon: Icons.mood_outlined,
      color: Color(0xFF42A5F5),
      route: AppRouter.moodTracker,
    ),
    'findDoctor': WellnessFeature(
      id: 'findDoctor',
      enLabel: 'Find a doctor',
      siLabel: 'වෛද්‍යවරයෙක් සොයන්න',
      icon: Icons.medical_services_outlined,
      color: Color(0xFFEF5350),
      route: AppRouter.findDoctor,
    ),
    'counsellorCall': WellnessFeature(
      id: 'counsellorCall',
      enLabel: 'Talk to a counsellor',
      siLabel: 'උපදේශක ඇමතුම',
      icon: Icons.headset_mic_outlined,
      color: Color(0xFF00897B),
      route: AppRouter.counsellorCall,
    ),
    'resources': WellnessFeature(
      id: 'resources',
      enLabel: 'Helpful resources',
      siLabel: 'සහායක සම්පත්',
      icon: Icons.library_books_outlined,
      color: Color(0xFF8D6E63),
      route: AppRouter.resources,
    ),
  };
}