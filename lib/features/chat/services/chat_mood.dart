import 'package:flutter/material.dart';
import 'feature_recommender.dart';

/// A discrete mood detected from a chat message, used to tint Willow's bubble.
enum ChatMood {
  anxious,
  stressed,
  sad,
  heavy,
  angry,
  lonely,
  tired,
  happy,
  neutral,
}

/// Colors for a [ChatMood]: bubble fill (light + dark theme), accent used for
/// the highlighted/quote text inside the bubble, and readable text colors.
class ChatMoodPalette {
  final Color bubbleLight;
  final Color bubbleDark;
  final Color accent;
  final Color textLight;
  final Color textDark;
  final List<Color> accents;

  const ChatMoodPalette({
    required this.bubbleLight,
    required this.bubbleDark,
    required this.accent,
    required this.textLight,
    required this.textDark,
    required this.accents,
  });
}

class ChatMoodDetector {
  static const List<(String, ChatMood)> _map = [
    ('crisis', ChatMood.neutral),
    ('anxiety', ChatMood.anxious),
    ('stress', ChatMood.stressed),
    ('heavySad', ChatMood.heavy),
    ('sad', ChatMood.sad),
    ('angry', ChatMood.angry),
    ('lonely', ChatMood.lonely),
    ('exhausted', ChatMood.tired),
    ('guilty', ChatMood.sad),
    ('exam', ChatMood.stressed),
    ('positive', ChatMood.happy),
  ];

  static ChatMood detect(String text, {required bool isSinhala}) {
    final lower = text.toLowerCase();
    final signals = isSinhala ? WellnessRecommender.siSignals : WellnessRecommender.enSignals;
    for (final (key, mood) in _map) {
      final words = signals[key] ?? const <String>[];
      if (words.isNotEmpty && words.any((word) => lower.contains(word))) {
        return mood;
      }
    }
    return ChatMood.neutral;
  }

  static ChatMoodPalette paletteFor(ChatMood mood) {
    switch (mood) {
      case ChatMood.anxious:
        return const ChatMoodPalette(
          bubbleLight: Color(0xFFE8F1FD),
          bubbleDark: Color(0xFF173856),
          accent: Color(0xFF1976D2),
          textLight: Color(0xFF123A68),
          textDark: Color(0xFFCFE6FF),
          accents: [Color(0xFF1976D2), Color(0xFF42A5F5), Color(0xFF64B5F6), Color(0xFF1E88E5)],
        );
      case ChatMood.stressed:
        return const ChatMoodPalette(
          bubbleLight: Color(0xFFE6F4EA),
          bubbleDark: Color(0xFF1E3A2E),
          accent: Color(0xFF2E7D32),
          textLight: Color(0xFF1F4A28),
          textDark: Color(0xFFCBEBD3),
          accents: [Color(0xFF2E7D32), Color(0xFF43A047), Color(0xFF66BB6A), Color(0xFF388E3C)],
        );
      case ChatMood.sad:
        return const ChatMoodPalette(
          bubbleLight: Color(0xFFF3EDFA),
          bubbleDark: Color(0xFF2A2140),
          accent: Color(0xFF7E57C2),
          textLight: Color(0xFF4A2C7A),
          textDark: Color(0xFFE6D9FB),
          accents: [Color(0xFF7E57C2), Color(0xFF9575CD), Color(0xFFB39DDB), Color(0xFF9C88D8)],
        );
      case ChatMood.heavy:
        return const ChatMoodPalette(
          bubbleLight: Color(0xFFE9E2F7),
          bubbleDark: Color(0xFF221A38),
          accent: Color(0xFF6A4FA3),
          textLight: Color(0xFF3E2A68),
          textDark: Color(0xFFDED0F5),
          accents: [Color(0xFF6A4FA3), Color(0xFF7B6FC2), Color(0xFF9575CD), Color(0xFF5E62B5)],
        );
      case ChatMood.angry:
        return const ChatMoodPalette(
          bubbleLight: Color(0xFFFCECEA),
          bubbleDark: Color(0xFF482126),
          accent: Color(0xFFEF5350),
          textLight: Color(0xFF7A2E24),
          textDark: Color(0xFFFFD9D4),
          accents: [Color(0xFFEF5350), Color(0xFFE57373), Color(0xFFFF8A80), Color(0xFFE5543F)],
        );
      case ChatMood.lonely:
        return const ChatMoodPalette(
          bubbleLight: Color(0xFFEBF2F4),
          bubbleDark: Color(0xFF223439),
          accent: Color(0xFF546E7A),
          textLight: Color(0xFF28434D),
          textDark: Color(0xFFD3E4E9),
          accents: [Color(0xFF546E7A), Color(0xFF78909C), Color(0xFF90A4AE), Color(0xFF607D8B)],
        );
      case ChatMood.tired:
        return const ChatMoodPalette(
          bubbleLight: Color(0xFFF3F0E9),
          bubbleDark: Color(0xFF38342A),
          accent: Color(0xFF8D8574),
          textLight: Color(0xFF443C2C),
          textDark: Color(0xFFE8E0D1),
          accents: [Color(0xFF8D8574), Color(0xFFA39B8A), Color(0xFFB8B09E), Color(0xFF7E7563)],
        );
      case ChatMood.happy:
        return const ChatMoodPalette(
          bubbleLight: Color(0xFFFFF3E2),
          bubbleDark: Color(0xFF3B3220),
          accent: Color(0xFFFB8C00),
          textLight: Color(0xFF6B4710),
          textDark: Color(0xFFFFE8C2),
          accents: [Color(0xFFFB8C00), Color(0xFFFFA726), Color(0xFFFFB74D), Color(0xFFF57C00)],
        );
      case ChatMood.neutral:
        return const ChatMoodPalette(
          bubbleLight: Color(0xFFFFFFFF),
          bubbleDark: Color(0xFF1E3535),
          accent: Color(0xFF5BA8A0),
          textLight: Color(0xFF1A4A4A),
          textDark: Color(0xFFFFFFFF),
          accents: [Color(0xFF5BA8A0), Color(0xFF4DB6AC), Color(0xFF26A69A), Color(0xFF66BB6A)],
        );
    }
  }
}