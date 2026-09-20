import 'package:flutter/material.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';
import 'package:mind_care_app/features/games/screens/bubble_blaster_game.dart';
import 'package:mind_care_app/features/games/screens/snake_game.dart';
import 'package:mind_care_app/features/games/screens/candy_crush_game.dart';
import 'package:mind_care_app/features/games/screens/puzzle_game.dart';
import 'package:mind_care_app/features/games/screens/word_puzzle_game.dart';
import 'package:mind_care_app/features/games/widgets/game_instructions_screen.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  void _openBubble(BuildContext context) {
    final s = LanguageProvider.of(context);
    showGameInstructions(
      context,
      emoji: '🎯',
      title: s.gameBubbleTitle,
      steps: s.bubbleHowTo,
      accentColor: const Color(0xFF5BA8A0),
      onStart: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BubbleBlasterGame()),
      ),
    );
  }

  void _openSnake(BuildContext context) {
    final s = LanguageProvider.of(context);
    showGameInstructions(
      context,
      emoji: '🐍',
      title: s.gameSnakeTitle,
      steps: s.snakeHowTo,
      accentColor: const Color(0xFF43A047),
      onStart: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SnakeGame()),
      ),
    );
  }

  void _openCandy(BuildContext context) {
    final s = LanguageProvider.of(context);
    showGameInstructions(
      context,
      emoji: '🍬',
      title: s.gameCandyCrushTitle,
      steps: s.candyHowTo,
      accentColor: const Color(0xFFEC407A),
      onStart: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CandyCrushGame()),
      ),
    );
  }

  void _openPuzzle(BuildContext context) {
    final s = LanguageProvider.of(context);
    showGameInstructions(
      context,
      emoji: '🧩',
      title: s.gamePuzzleTitle,
      steps: s.puzzleHowTo,
      accentColor: const Color(0xFF2196F3),
      onStart: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PuzzleGame()),
      ),
    );
  }

  void _openWord(BuildContext context) {
    final s = LanguageProvider.of(context);
    showGameInstructions(
      context,
      emoji: '🔤',
      title: s.gameWordPuzzleTitle,
      steps: s.wordHowTo,
      accentColor: const Color(0xFF8BC34A),
      onStart: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WordPuzzleGame()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = LanguageProvider.of(context);

    final games = [
      _GameInfo(
        emoji: '🎯',
        title: s.gameBubbleTitle,
        description: s.gameBubbleDesc,
        mood: s.gameBubbleMood,
        color: isDark ? const Color(0xFF002A2E) : const Color(0xFFE0F7FA),
        accentColor: const Color(0xFF5BA8A0),
        onTap: () => _openBubble(context),
      ),
      _GameInfo(
        emoji: '🐍',
        title: s.gameSnakeTitle,
        description: s.gameSnakeDesc,
        mood: s.gameSnakeMood,
        color: isDark ? const Color(0xFF0D1F0D) : const Color(0xFFE8F5E9),
        accentColor: const Color(0xFF43A047),
        onTap: () => _openSnake(context),
      ),
      _GameInfo(
        emoji: '🍬',
        title: s.gameCandyCrushTitle,
        description: s.gameCandyCrushDesc,
        mood: s.gameCandyCrushMood,
        color: isDark ? const Color(0xFF1A152A) : const Color(0xFFF3E5F5),
        accentColor: const Color(0xFFEC407A),
        onTap: () => _openCandy(context),
      ),
      _GameInfo(
        emoji: '🧩',
        title: s.gamePuzzleTitle,
        description: s.gamePuzzleDesc,
        mood: s.gamePuzzleMood,
        color: isDark ? const Color(0xFF0D1A2A) : const Color(0xFFE3F2FD),
        accentColor: const Color(0xFF2196F3),
        onTap: () => _openPuzzle(context),
      ),
      _GameInfo(
        emoji: '🔤',
        title: s.gameWordPuzzleTitle,
        description: s.gameWordPuzzleDesc,
        mood: s.gameWordPuzzleMood,
        color: isDark ? const Color(0xFF1A2A0A) : const Color(0xFFF1F8E9),
        accentColor: const Color(0xFF8BC34A),
        onTap: () => _openWord(context),
      ),
    ];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1A2A2A)
          : const Color(0xFFF0F9F9),
      body: LeafBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: isDark ? Colors.white : const Color(0xFF1A4A4A),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      s.gameHub,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A4A4A),
                      ),
                    ),
                    const Spacer(),
                    const Text('🎮', style: TextStyle(fontSize: 28)),
                  ],
                ),
              ),
              // Big icon + tagline
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF5BA8A0,
                              ).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🎮', style: TextStyle(fontSize: 48)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.playToRelax,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF5BA8A0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Game list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: games.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      _GameCard(game: games[i], isDark: isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameInfo {
  final String emoji, title, description, mood;
  final Color color, accentColor;
  final VoidCallback onTap;
  _GameInfo({
    required this.emoji,
    required this.title,
    required this.description,
    required this.mood,
    required this.color,
    required this.accentColor,
    required this.onTap,
  });
}

class _GameCard extends StatelessWidget {
  final _GameInfo game;
  final bool isDark;
  const _GameCard({required this.game, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: game.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: game.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: game.accentColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: game.accentColor.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Large icon
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: game.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: game.accentColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(game.emoji, style: const TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            game.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A3333),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: game.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            game.mood,
                            style: TextStyle(
                              fontSize: 9,
                              color: game.accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF4A6A6A),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.play_circle_rounded,
                color: game.accentColor,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
