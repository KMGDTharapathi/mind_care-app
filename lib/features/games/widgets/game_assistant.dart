import 'package:flutter/material.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';

/// A discreet in-game assistant: a small circular button the player can tap
/// at any time during play to get short, encouraging contextual tips.
class GameAssistant extends StatelessWidget {
  final String emoji;
  final String title;
  final List<String> tips;
  final Color accentColor;

  const GameAssistant({
    super.key,
    required this.emoji,
    required this.title,
    required this.tips,
    required this.accentColor,
  });

  void _open(BuildContext context) {
    final s = LanguageProvider.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF24243a) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.gameAssistantTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A3333),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < tips.length; i++) ...[
                _TipRow(index: i + 1, text: tips[i], accentColor: accentColor),
                if (i != tips.length - 1) const SizedBox(height: 12),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(s.gameAssistantGotIt),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Game assistant',
      button: true,
      child: Tooltip(
        message: 'Assistant',
        child: InkWell(
          onTap: () => _open(context),
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.psychology_alt_rounded, color: accentColor, size: 22),
          ),
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final int index;
  final String text;
  final Color accentColor;

  const _TipRow({
    required this.index,
    required this.text,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white70 : const Color(0xFF1A3333),
            ),
          ),
        ),
      ],
    );
  }
}