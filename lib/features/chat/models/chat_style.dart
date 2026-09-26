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

  const ChatFont({
    required this.id,
    required this.enName,
    required this.siName,
    this.family,
  });

  static const Map<String, ChatFont> byId = {
    'normal': ChatFont(
      id: 'normal',
      enName: 'Default',
      siName: 'සම්මත',
    ),
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
  };

  static ChatFont fromId(String? id) => byId[id] ?? byId['normal']!;
}