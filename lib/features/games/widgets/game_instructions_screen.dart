import 'package:flutter/material.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';

/// A short, clear pre-game instructions screen.
///
/// Shown before a mini-game starts. Tapping "Start" pops this screen and runs
/// [onStart] (which typically pushes the actual game). Each child game provides
/// its own [emoji], [title], accent color and short [steps].
class GameInstructionsScreen extends StatelessWidget {
  final String emoji;
  final String title;
  final List<String> steps;
  final Color accentColor;
  final VoidCallback onStart;

  const GameInstructionsScreen({
    super.key,
    required this.emoji,
    required this.title,
    required this.steps,
    required this.accentColor,
    required this.onStart,
  });

  void _start(BuildContext context) {
    Navigator.of(context).pop();
    onStart();
  }

  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A2A2A) : const Color(0xFFF0F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A4A4A),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: LeafBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                  child: Column(
                    children: [
                      // Emoji + title
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.35),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 48)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1A4A4A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.howToPlay,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Short steps
                      for (var i = 0; i < steps.length; i++) ...[
                        _StepRow(
                          number: (i + 1).toString(),
                          text: steps[i],
                          accentColor: accentColor,
                          isDark: isDark,
                        ),
                        if (i != steps.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
              // Start button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () => _start(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text(
                      '${s.play} ▶',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;
  final Color accentColor;
  final bool isDark;

  const _StepRow({
    required this.number,
    required this.text,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: accentColor.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? Colors.white70 : const Color(0xFF1A3333),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Convenience helper for pushing the instructions screen from the game hub.
Future<void> showGameInstructions(
  BuildContext context, {
  required String emoji,
  required String title,
  required List<String> steps,
  required Color accentColor,
  required VoidCallback onStart,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => GameInstructionsScreen(
        emoji: emoji,
        title: title,
        steps: steps,
        accentColor: accentColor,
        onStart: onStart,
      ),
    ),
  );
}