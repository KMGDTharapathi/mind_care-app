import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';
import '../widgets/game_assistant.dart';

class PuzzleGame extends StatefulWidget {
  const PuzzleGame({super.key});

  @override
  State<PuzzleGame> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame>
    with SingleTickerProviderStateMixin {
  static const int _gridSize = 4; // 4x4 = 15 puzzle + 1 empty
  static const int _totalTiles = _gridSize * _gridSize;

  late List<int> _tiles;
  int _emptyIndex = _totalTiles - 1;
  int _moves = 0;
  int _bestMoves = 0;
  bool _isSolved = false;
  late AnimationController _animCtrl;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _shuffle();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _shuffle() {
    do {
      _tiles = List.generate(_totalTiles, (i) => i + 1);
      _tiles[_totalTiles - 1] = 0; // 0 = empty
      // Shuffle using Fisher-Yates
      for (int i = _totalTiles - 1; i > 0; i--) {
        final j = _random.nextInt(i + 1);
        final temp = _tiles[i];
        _tiles[i] = _tiles[j];
        _tiles[j] = temp;
      }
    } while (!_isSolvable() || _isSolvedState());

    _emptyIndex = _tiles.indexOf(0);
    _moves = 0;
    _isSolved = false;
  }

  bool _isSolvable() {
    int inversions = 0;
    final flat = _tiles.where((t) => t != 0).toList();
    for (int i = 0; i < flat.length; i++) {
      for (int j = i + 1; j < flat.length; j++) {
        if (flat[i] > flat[j]) inversions++;
      }
    }
    final emptyRow = _tiles.indexOf(0) ~/ 4;
    return (inversions + emptyRow) % 2 == 0;
  }

  bool _isSolvedState() {
    for (int i = 0; i < _totalTiles - 1; i++) {
      if (_tiles[i] != i + 1) return false;
    }
    return _tiles[_totalTiles - 1] == 0;
  }

  void _onTap(int index) {
    if (_isSolved) return;

    final emptyRow = _emptyIndex ~/ 4;
    final emptyCol = _emptyIndex % 4;
    final tapRow = index ~/ 4;
    final tapCol = index % 4;

    final isAdjacent = (tapRow == emptyRow && (tapCol - emptyCol).abs() == 1) ||
        (tapCol == emptyCol && (tapRow - emptyRow).abs() == 1);

    if (!isAdjacent) return;

    setState(() {
      _tiles[_emptyIndex] = _tiles[index];
      _tiles[index] = 0;
      _emptyIndex = index;
      _moves++;

      if (_isSolvedState()) {
        _isSolved = true;
        if (_bestMoves == 0 || _moves < _bestMoves) {
          _bestMoves = _moves;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1A2A) : const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: Text(s.gamePuzzleTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0D1A2A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GameAssistant(
              emoji: '🧠',
              title: s.gamePuzzleTitle,
              tips: s.puzzleTips,
              accentColor: const Color(0xFF2196F3),
            ),
          ),
        ],
      ),
      body: LeafBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Stats
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatChip(
                      icon: Icons.swap_horiz_rounded,
                      label: s.isSinhala ? 'ගමන්' : 'Moves',
                      value: '$_moves',
                      color: const Color(0xFF2196F3),
                      isDark: isDark,
                    ),
                    _StatChip(
                      icon: Icons.emoji_events_rounded,
                      label: s.isSinhala ? 'හොඳම' : 'Best',
                      value: _bestMoves > 0 ? '$_bestMoves' : '-',
                      color: const Color(0xFFFFC107),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              // Puzzle grid
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0D1A2A).withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1,
                        ),
                        itemCount: 16,
                        itemBuilder: (_, index) {
                          final value = _tiles[index];
                          final isEmpty = value == 0;
                          return _PuzzleTile(
                            value: value,
                            isEmpty: isEmpty,
                            onTap: () => _onTap(index),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Solved message
              _isSolved ? _buildSolvedMessage() : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSolvedMessage() {
    final s = LanguageProvider.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _isSolved
        ? Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  s.isSinhala ? 'සාර්ථකයි!' : 'Solved!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0D1A2A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${s.isSinhala ? "ගමන්" : "Moves"}: $_moves',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(_shuffle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    s.isSinhala ? 'නැවත ආරම්භ කරන්න' : 'Play Again',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
  }
}

class _PuzzleTile extends StatelessWidget {
  final int value;
  final bool isEmpty;
  final VoidCallback onTap;

  const _PuzzleTile({
    required this.value,
    required this.isEmpty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isEmpty) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400, width: 1),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2196F3).withValues(alpha: 0.8),
              const Color(0xFF1976D2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2196F3).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$value',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}