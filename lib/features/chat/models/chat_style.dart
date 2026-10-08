import 'package:flutter/material.dart';

/// A user-selectable color theme for the Willow chat screen. Each theme changes
/// the chat background, header, accent, and user-bubble tint. Willow's
/// mood-colored bubbles (see ChatMoodDetector) still take precedence for the
/// AI replies — the theme provides the neutral/mood accent + surrounding chrome.
class ChatTheme {
  final String id;
  final String enName;
  final String siName;
  final Color backgroundLight;
  final Color backgroundDark;
  final Color headerLight;
  final Color headerDark;
  final Color accentLight;
  final Color accentDark;
  final Color userBubbleLight;
  final Color userBubbleDark;

  const ChatTheme({
    required this.id,
    required this.enName,
    required this.siName,
    required this.backgroundLight,
    required this.backgroundDark,
    required this.headerLight,
    required this.headerDark,
    required this.accentLight,
    required this.accentDark,
    required this.userBubbleLight,
    required this.userBubbleDark,
  });

  Color background(bool dark) => dark ? backgroundDark : backgroundLight;
  Color header(bool dark) => dark ? headerDark : headerLight;
  Color accent(bool dark) => dark ? accentDark : accentLight;
  Color userBubble(bool dark) => dark ? userBubbleDark : userBubbleLight;

  static const Map<String, ChatTheme> byId = {
    'spring': ChatTheme(
      id: 'spring',
      enName: 'Spring teal',
      siName: 'වසන්ත',
      backgroundLight: Color(0xFFF0F9F9),
      backgroundDark: Color(0xFF0D1A1A),
      headerLight: Color(0xFF5BA8A0),
      headerDark: Color(0xFF1A4542),
      accentLight: Color(0xFF5BA8A0),
      accentDark: Color(0xFF80CBC4),
      userBubbleLight: Color(0xFFDCF8C6),
      userBubbleDark: Color(0xFF1B5E20),
    ),
    'ocean': ChatTheme(
      id: 'ocean',
      enName: 'Ocean blue',
      siName: 'මුහුදු නිල්',
      backgroundLight: Color(0xFFEEF5FC),
      backgroundDark: Color(0xFF0D1726),
      headerLight: Color(0xFF4A90D9),
      headerDark: Color(0xFF1B3A63),
      accentLight: Color(0xFF2196F3),
      accentDark: Color(0xFF81D4FA),
      userBubbleLight: Color(0xFFDBEAFA),
      userBubbleDark: Color(0xFF1D4A8A),
    ),
    'sunset': ChatTheme(
      id: 'sunset',
      enName: 'Sunset peach',
      siName: 'හිරු බැසීම',
      backgroundLight: Color(0xFFFDF2E9),
      backgroundDark: Color(0xFF241912),
      headerLight: Color(0xFFE68A5E),
      headerDark: Color(0xFF4A2B2B),
      accentLight: Color(0xFFF97B4F),
      accentDark: Color(0xFFFFAB91),
      userBubbleLight: Color(0xFFFFE3CE),
      userBubbleDark: Color(0xFF5C2E1F),
    ),
    'lavender': ChatTheme(
      id: 'lavender',
      enName: 'Lavender dream',
      siName: 'ලැෙවන්ඩර්',
      backgroundLight: Color(0xFFF7F2FC),
      backgroundDark: Color(0xFF1B1526),
      headerLight: Color(0xFF9575CD),
      headerDark: Color(0xFF332552),
      accentLight: Color(0xFF7E57C2),
      accentDark: Color(0xFFB39DDB),
      userBubbleLight: Color(0xFFEAE2F8),
      userBubbleDark: Color(0xFF4A3670),
    ),
    'forest': ChatTheme(
      id: 'forest',
      enName: 'Forest green',
      siName: 'වනාන්තර',
      backgroundLight: Color(0xFFF1F7EE),
      backgroundDark: Color(0xFF0E1D13),
      headerLight: Color(0xFF57A166),
      headerDark: Color(0xFF1E3D28),
      accentLight: Color(0xFF43A047),
      accentDark: Color(0xFF81C784),
      userBubbleLight: Color(0xFFDCEEDD),
      userBubbleDark: Color(0xFF1F4726),
    ),
    'blush': ChatTheme(
      id: 'blush',
      enName: 'Pastel blush',
      siName: 'පැස්ටල් රෝස',
      backgroundLight: Color(0xFFFDF2F7),
      backgroundDark: Color(0xFF24121E),
      headerLight: Color(0xFFF48FB1),
      headerDark: Color(0xFF4A2540),
      accentLight: Color(0xFFEC407A),
      accentDark: Color(0xFFF48FB1),
      userBubbleLight: Color(0xFFFCE4EC),
      userBubbleDark: Color(0xFF70254A),
    ),
    'mint': ChatTheme(
      id: 'mint',
      enName: 'Pastel mint',
      siName: 'පැස්ටල් මින්ත්',
      backgroundLight: Color(0xFFF0FBF7),
      backgroundDark: Color(0xFF0D1F19),
      headerLight: Color(0xFF4DB6AC),
      headerDark: Color(0xFF1B4A43),
      accentLight: Color(0xFF26A69A),
      accentDark: Color(0xFF80CBC4),
      userBubbleLight: Color(0xFFE0F2F1),
      userBubbleDark: Color(0xFF1A4A42),
    ),
    'butter': ChatTheme(
      id: 'butter',
      enName: 'Pastel butter',
      siName: 'පැස්ටල් කහ',
      backgroundLight: Color(0xFFFDFBF0),
      backgroundDark: Color(0xFF242110),
      headerLight: Color(0xFFFFD54F),
      headerDark: Color(0xFF4A3D1C),
      accentLight: Color(0xFFFFC107),
      accentDark: Color(0xFFFFE082),
      userBubbleLight: Color(0xFFFFF8E1),
      userBubbleDark: Color(0xFF5C4A12),
    ),
    'sky': ChatTheme(
      id: 'sky',
      enName: 'Pastel sky',
      siName: 'පැස්ටල් නිල්',
      backgroundLight: Color(0xFFF4FAFE),
      backgroundDark: Color(0xFF0E1D2A),
      headerLight: Color(0xFF81D4FA),
      headerDark: Color(0xFF1C3A50),
      accentLight: Color(0xFF29B6F6),
      accentDark: Color(0xFF81D4FA),
      userBubbleLight: Color(0xFFE1F5FE),
      userBubbleDark: Color(0xFF16405C),
    ),
    'peach': ChatTheme(
      id: 'peach',
      enName: 'Pastel peach',
      siName: 'පැස්ටල් පීච්',
      backgroundLight: Color(0xFFFEF6F1),
      backgroundDark: Color(0xFF251A13),
      headerLight: Color(0xFFFFB74D),
      headerDark: Color(0xFF4A3018),
      accentLight: Color(0xFFFF9800),
      accentDark: Color(0xFFFFCC80),
      userBubbleLight: Color(0xFFFFF3E0),
      userBubbleDark: Color(0xFF5C3A10),
    ),
  };

  static ChatTheme fromId(String? id) => byId[id] ?? byId['spring']!;
}

/// A user-selectable font face for the chat messages. Uses built-in generic
/// families so no extra font assets are needed.
class ChatFont {
  final String id;
  final String enName;
  final String siName;
  final String? family;
  final FontWeight? weight;
  final FontStyle? style;

  const ChatFont({
    required this.id,
    required this.enName,
    required this.siName,
    this.family,
    this.weight,
    this.style,
  });

  static const Map<String, ChatFont> byId = {
    'normal': ChatFont(id: 'normal', enName: 'Default', siName: 'සම්මත'),
    'serif': ChatFont(
      id: 'serif',
      enName: 'Serif',
      siName: 'සෙරිෆ්',
      family: 'serif',
    ),
    'mono': ChatFont(
      id: 'mono',
      enName: 'Monospace',
      siName: 'මොනෝ',
      family: 'monospace',
    ),
    'sans_condensed': ChatFont(
      id: 'sans_condensed',
      enName: 'Condensed',
      siName: 'සංයුක්ත',
      family: 'sans-serif-condensed',
    ),
    'sans_light': ChatFont(
      id: 'sans_light',
      enName: 'Light sans',
      siName: 'සිහින්',
      family: 'sans-serif-light',
    ),
    'sans_medium': ChatFont(
      id: 'sans_medium',
      enName: 'Medium sans',
      siName: 'මධ්‍යම',
      family: 'sans-serif-medium',
    ),
    'cursive': ChatFont(
      id: 'cursive',
      enName: 'Cursive',
      siName: 'අකුරු සැරසිලි',
      family: 'cursive',
    ),
    'casual': ChatFont(
      id: 'casual',
      enName: 'Casual',
      siName: 'කැජුවල්',
      family: 'casual',
    ),
    'serif_medium': ChatFont(
      id: 'serif_medium',
      enName: 'Serif medium',
      siName: 'සෙරිෆ් මධ්‍යම',
      family: 'serif',
      weight: FontWeight.w600,
    ),
  };

  static ChatFont fromId(String? id) => byId[id] ?? byId['normal']!;
}
