import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/game_assistant.dart';

/// A polished match-3 game with:
///  - multiple levels with target scores & move budgets
///  - special candies (4-match = line clear, 5-match = color clear)
///  - combos, best-score persistence and deadlock reshuffling
class CandyCrushGame extends StatefulWidget {
  const CandyCrushGame({super.key});

  @override
  State<CandyCrushGame> createState() => _CandyCrushGameState();
}

class _Level {
  final int targetScore;
  final int moves;
  const _Level(this.targetScore, this.moves);
}

const List<_Level> _levels = [
  _Level(800, 20),
  _Level(1500, 22),
  _Level(2200, 24),
  _Level(3200, 26),
  _Level(4500, 28),
  _Level(6000, 30),
  _Level(8000, 32),
];

enum CandySpecialKind { none, row, col, rainbow }

class _CandyCrushGameState extends State<CandyCrushGame> {
  static const int _rows = 8;
  static const int _cols = 8;
  static const List<CandyType> _candyTypes = CandyType.values;
  static const String _bestKey = 'candy_crush_best';

  late List<List<Candy?>> _board;
  int _score = 0;
  int _moves = 0;
  int _levelIndex = 0;
  int _bestScore = 0;
  int _combo = 0;
  Candy? _selected;
  bool _isAnimating = false;
  bool _levelComplete = false;
  final _random = math.Random();

  int get _targetScore => _levels[_levelIndex].targetScore;

  @override
  void initState() {
    super.initState();
    _startLevel(_levelIndex);
    _loadBestScore();
  }

  Future<void> _loadBestScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final best = prefs.getInt(_bestKey) ?? 0;
      if (mounted && best > _bestScore) {
        setState(() => _bestScore = best);
      }
    } catch (_) {}
  }

  void _startLevel(int index) {
    _levelIndex = index;
    _score = 0;
    _combo = 0;
    _moves = _levels[index].moves;
    _levelComplete = false;
    _selected = null;
    _initBoard();
  }

  void _initBoard() {
    _board = List.generate(_rows, (_) => List.filled(_cols, null));
    _fillBoard();
    _ensurePlayable();
  }

  void _fillBoard() {
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        if (_board[r][c] == null) {
          _board[r][c] = Candy(
            type: _candyTypes[_random.nextInt(_candyTypes.length)],
            row: r,
            col: c,
          );
        }
      }
    }
  }

  /// Regenerates the board until there are no pre-existing matches AND at
  /// least one valid move is available.
  void _ensurePlayable() {
    var guard = 0;
    while ((_findMatchGroups().isNotEmpty || !_hasPossibleMoves()) &&
        guard < 20) {
      guard++;
      for (var r = 0; r < _rows; r++) {
        for (var c = 0; c < _cols; c++) {
          _board[r][c] = Candy(
            type: _candyTypes[_random.nextInt(_candyTypes.length)],
            row: r,
            col: c,
          );
        }
      }
    }
  }

  bool _hasPossibleMoves() {
    final possibilities = [(-1, 0), (1, 0), (0, -1), (0, 1)];
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        for (final (dr, dc) in possibilities) {
          final nr = r + dr;
          final nc = c + dc;
          if (nr < 0 || nr >= _rows || nc < 0 || nc >= _cols) continue;
          _swapInPlace(r, c, nr, nc);
          final hasMatch =
              _checkMatchAt(nr, nc) || _checkMatchAt(r, c);
          _swapInPlace(r, c, nr, nc);
          if (hasMatch) return true;
        }
      }
    }
    return false;
  }

  void _swapInPlace(int r1, int c1, int r2, int c2) {
    final a = _board[r1][c1];
    final b = _board[r2][c2];
    if (a == null || b == null) return;
    _board[r1][c1] = b;
    _board[r2][c2] = a;
    a.row = r2;
    a.col = c2;
    b.row = r1;
    b.col = c1;
  }

  // ── Match detection ────────────────────────────────────────────────────────

  bool _checkMatchAt(int r, int c) {
    final candy = _board[r][c];
    if (candy == null) return false;
    var horizontal = 1;
    for (var dc = 1; c + dc < _cols; dc++) {
      if (_board[r][c + dc]?.type == candy.type) {
        horizontal++;
      } else {
        break;
      }
    }
    for (var dc = -1; c + dc >= 0; dc--) {
      if (_board[r][c + dc]?.type == candy.type) {
        horizontal++;
      } else {
        break;
      }
    }
    if (horizontal >= 3) return true;

    var vertical = 1;
    for (var dr = 1; r + dr < _rows; dr++) {
      if (_board[r + dr][c]?.type == candy.type) {
        vertical++;
      } else {
        break;
      }
    }
    for (var dr = -1; r + dr >= 0; dr--) {
      if (_board[r + dr][c]?.type == candy.type) {
        vertical++;
      } else {
        break;
      }
    }
    return vertical >= 3;
  }

  /// Returns connected same-type groups of size >= 3.
  List<Set<Candy>> _findMatchGroups() {
    final visited = <Candy>{};
    final groups = <Set<Candy>>[];
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final candy = _board[r][c];
        if (candy == null || visited.contains(candy)) continue;
        final group = _flood(candy);
        if (group.length >= 3) {
          groups.add(group);
          visited.addAll(group);
        }
      }
    }
    return groups;
  }

  Set<Candy> _flood(Candy start) {
    final result = <Candy>{start};
    final queue = <Candy>[start];
    while (queue.isNotEmpty) {
      final cur = queue.removeLast();
      final neighbours = [
        (cur.row + 1, cur.col),
        (cur.row - 1, cur.col),
        (cur.row, cur.col + 1),
        (cur.row, cur.col - 1),
      ];
      for (final (r, c) in neighbours) {
        if (r < 0 || r >= _rows || c < 0 || c >= _cols) continue;
        final n = _board[r][c];
        if (n == null || n.type != cur.type || result.contains(n)) continue;
        result.add(n);
        queue.add(n);
      }
    }
    return result;
  }

  CandySpecialKind _newSpecialKind(Set<Candy> group) {
    if (group.length >= 5) return CandySpecialKind.rainbow;
    if (group.length < 4) return CandySpecialKind.none;
    final rows = group.map((e) => e.row).toSet();
    final cols = group.map((e) => e.col).toSet();
    if (rows.length == 1) return CandySpecialKind.row;
    if (cols.length == 1) return CandySpecialKind.col;
    return CandySpecialKind.none;
  }

  Candy _anchorOf(Iterable<Candy> group) {
    return group.reduce(
      (a, b) =>
          (a.row < b.row || (a.row == b.row && a.col < b.col)) ? a : b,
    );
  }

  /// Cells cleared by activating a special candy (line / column / color).
  Set<Candy> _clearCellsFor(Candy special) {
    final cleared = <Candy>{};
    switch (special.specialKind) {
      case CandySpecialKind.row:
        for (var c = 0; c < _cols; c++) {
          final candy = _board[special.row][c];
          if (candy != null) cleared.add(candy);
        }
        break;
      case CandySpecialKind.col:
        for (var r = 0; r < _rows; r++) {
          final candy = _board[r][special.col];
          if (candy != null) cleared.add(candy);
        }
        break;
      case CandySpecialKind.rainbow:
        for (var r = 0; r < _rows; r++) {
          for (var c = 0; c < _cols; c++) {
            final candy = _board[r][c];
            if (candy != null && candy.type == special.type) {
              cleared.add(candy);
            }
          }
        }
        break;
      case CandySpecialKind.none:
        break;
    }
    // The special itself is always cleared too.
    cleared.add(special);
    return cleared;
  }

  // ── Gameplay ───────────────────────────────────────────────────────────────

  void _onTap(int r, int c) {
    if (_isAnimating || _moves <= 0 || _levelComplete) return;
    final candy = _board[r][c];
    if (candy == null) return;

    if (_selected == null) {
      setState(() => _selected = candy);
    } else if (_selected == candy) {
      setState(() => _selected = null);
    } else if (_areAdjacent(_selected!, candy)) {
      _trySwap(_selected!, candy);
    } else {
      setState(() => _selected = candy);
    }
  }

  bool _areAdjacent(Candy a, Candy b) {
    return (a.row == b.row && (a.col - b.col).abs() == 1) ||
        (a.col == b.col && (a.row - b.row).abs() == 1);
  }

  void _trySwap(Candy a, Candy b) {
    setState(() {
      _isAnimating = true;
      _swapInPlace(a.row, a.col, b.row, b.col);
      _selected = null;
    });

    final aSpecial = a.isSpecial;
    final bSpecial = b.isSpecial;

    if (aSpecial || bSpecial) {
      // Swapping a special candy detonates it immediately.
      _moves--;
      _combo = 0;
      _detonateSpecial(aSpecial ? a : b);
      return;
    }

    final hasMatch = _checkMatchAt(a.row, a.col) || _checkMatchAt(b.row, b.col);
    if (!hasMatch) {
      Future.delayed(const Duration(milliseconds: 160), () {
        if (mounted) {
          setState(() => _swapInPlace(a.row, a.col, b.row, b.col));
          _removeMatchesNext();
        }
      });
      return;
    }

    _moves--;
    _combo = 0;
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _removeMatchesNext();
    });
  }

  void _detonateSpecial(Candy special) {
    setState(() {}); // show the swap
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      _combo++;
      final cleared = _clearCellsFor(special);
      _score += cleared.length * 10 * _combo;
      _applyRemoval(cleared);
    });
  }

  /// One pass: resolve current matches (and specials inside them), create new
  /// specials, drop, fill, then cascade.
  void _removeMatchesNext() {
    final groups = _findMatchGroups();
    if (groups.isEmpty) {
      if (!_hasPossibleMoves()) {
        // Deadlock — regenerate the board so the game stays playable.
        setState(() {
          _isAnimating = false;
          _initBoard();
        });
      } else {
        setState(() => _isAnimating = false);
      }
      _checkEndConditions();
      return;
    }

    _combo++;
    final toClear = <Candy>{};

    for (final group in groups) {
      // Activate any special candy that is part of a match (chain reactions).
      for (final candy in group) {
        if (candy.isSpecial) {
          toClear.addAll(_clearCellsFor(candy));
        }
      }
      final kind = _newSpecialKind(group);
      final plain = group.where((c) => !c.isSpecial).toList();
      if (kind == CandySpecialKind.none || plain.isEmpty) {
        toClear.addAll(plain);
      } else {
        // Re-purpose one plain candy of the group as the new special candy.
        final anchor = _anchorOf(plain);
        toClear.addAll(plain.where((c) => c != anchor));
        anchor.specialKind = kind;
      }
    }

    _score += toClear.length * 10 * _combo;
    _applyRemoval(toClear);
  }

  void _applyRemoval(Set<Candy> toClear) {
    if (!mounted) return;
    setState(() {
      for (final candy in toClear) {
        _board[candy.row][candy.col] = null;
      }
    });
    _dropAndFill();
    if (_hasCascadingMatches()) {
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) _removeMatchesNext();
      });
    } else {
      setState(() => _isAnimating = false);
      _checkEndConditions();
    }
  }

  bool _hasCascadingMatches() =>
      _findMatchGroups().isNotEmpty || !_hasPossibleMoves();

  void _dropAndFill() {
    for (var c = 0; c < _cols; c++) {
      var writeRow = _rows - 1;
      for (var r = _rows - 1; r >= 0; r--) {
        final candy = _board[r][c];
        if (candy != null) {
          if (writeRow != r) {
            _board[writeRow][c] = candy;
            candy.row = writeRow;
            _board[r][c] = null;
          }
          writeRow--;
        }
      }
    }
    _fillBoard();
  }

  void _checkEndConditions() {
    if (_levelComplete) return;
    final reachedTarget = _score >= _targetScore;
    if (!reachedTarget && _moves > 0) return;
    setState(() {
      if (reachedTarget) {
        _levelComplete = true;
      }
      if (_score > _bestScore) {
        _bestScore = _score;
        _persistBest();
      }
    });
  }

  Future<void> _persistBest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bestKey, _bestScore);
    } catch (_) {}
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final levelComplete = _levelComplete;
    final gameOver = _moves <= 0 && !_levelComplete;
    final progress = (_score / _targetScore).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1A152A)
          : const Color(0xFFF3E5F5),
      appBar: AppBar(
        title: Text(s.gameCandyCrushTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A152A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GameAssistant(
              emoji: '🧠',
              title: s.gameCandyCrushTitle,
              tips: s.candyTips,
              accentColor: const Color(0xFFEC407A),
            ),
          ),
        ],
      ),
      body: LeafBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Level + target progress
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.isSinhala
                              ? 'මට්ටම ${_levelIndex + 1}'
                              : 'Level ${_levelIndex + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEC407A),
                          ),
                        ),
                        Text(
                          s.isSinhala
                              ? 'ඉලක්කය: $_targetScore'
                              : 'Target: $_targetScore',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF6A1B9A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFEC407A)
                            .withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFEC407A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatChip(
                      icon: Icons.star_rounded,
                      label: s.isSinhala ? 'ලකුණු' : 'Score',
                      value: '$_score',
                      color: const Color(0xFFEC407A),
                      isDark: isDark,
                    ),
                    _StatChip(
                      icon: Icons.swap_horiz_rounded,
                      label: s.isSinhala ? 'ගමන්' : 'Moves',
                      value: '$_moves',
                      color: const Color(0xFFEC407A),
                      isDark: isDark,
                    ),
                    _StatChip(
                      icon: Icons.local_fire_department_rounded,
                      label: s.isSinhala ? 'කොම්බෝ' : 'Combo',
                      value: 'x$_combo',
                      color: const Color(0xFFFFA726),
                      isDark: isDark,
                    ),
                    _StatChip(
                      icon: Icons.emoji_events_rounded,
                      label: s.isSinhala ? 'වාර්තාව' : 'Best',
                      value: '$_bestScore',
                      color: const Color(0xFFFFD54F),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              // Board
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A152A).withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEC407A)
                                .withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _cols,
                              childAspectRatio: 1,
                            ),
                        itemCount: _rows * _cols,
                        itemBuilder: (_, index) {
                          final r = index ~/ _cols;
                          final c = index % _cols;
                          final candy = _board[r][c];
                          final isSelected = _selected == candy;
                          return _CandyWidget(
                            candy: candy,
                            isSelected: isSelected,
                            enabled: !_isAnimating &&
                                !_levelComplete &&
                                _moves > 0,
                            onTap: () => _onTap(r, c),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // End-of-level panel
              if (levelComplete || gameOver) ...[
                _EndPanel(
                  isWin: levelComplete,
                  score: _score,
                  isDark: isDark,
                  primaryLabel: s.isSinhala
                      ? (levelComplete
                            ? 'මට්ටම සම්පූර්ණයි!'
                            : 'ක්‍රීඩා අවසන්')
                      : (levelComplete
                            ? 'Level Complete!'
                            : 'Game Over'),
                  isLastLevel: _levelIndex == _levels.length - 1,
                  onPlayAgain: () => setState(() {
                    _startLevel(_levelIndex);
                  }),
                  onNextLevel: () => setState(() {
                    _startLevel(
                      _levelIndex < _levels.length - 1
                          ? _levelIndex + 1
                          : _levelIndex,
                    );
                  }),
                ),
              ] else
                const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

enum CandyType {
  red,
  blue,
  green,
  yellow,
  purple,
  orange,
}

class Candy {
  final CandyType type;
  int row;
  int col;
  CandySpecialKind specialKind = CandySpecialKind.none;

  Candy({required this.type, required this.row, required this.col});

  bool get isSpecial => specialKind != CandySpecialKind.none;

  Color get color {
    switch (type) {
      case CandyType.red:
        return const Color(0xFFE53935);
      case CandyType.blue:
        return const Color(0xFF1E88E5);
      case CandyType.green:
        return const Color(0xFF43A047);
      case CandyType.yellow:
        return const Color(0xFFFDD835);
      case CandyType.purple:
        return const Color(0xFF8E24AA);
      case CandyType.orange:
        return const Color(0xFFF4511E);
    }
  }

  IconData get icon {
    switch (type) {
      case CandyType.red:
        return Icons.favorite_rounded;
      case CandyType.blue:
        return Icons.water_drop_rounded;
      case CandyType.green:
        return Icons.eco_rounded;
      case CandyType.yellow:
        return Icons.star_rounded;
      case CandyType.purple:
        return Icons.auto_awesome_rounded;
      case CandyType.orange:
        return Icons.circle_rounded;
    }
  }
}

class _CandyWidget extends StatelessWidget {
  final Candy? candy;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _CandyWidget({
    required this.candy,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = candy;
    if (c == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: c.color.withValues(alpha: 0.9),
          shape: c.isSpecial ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: c.isSpecial ? BorderRadius.circular(8) : null,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: c.color.withValues(alpha: 0.5),
              blurRadius: isSelected ? 12 : 6,
              spreadRadius: isSelected ? 2 : 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: c.isSpecial
              ? Icon(
                  c.specialKind == CandySpecialKind.rainbow
                      ? Icons.auto_awesome_rounded
                      : Icons.bolt_rounded,
                  color: Colors.white,
                  size: 18,
                )
              : Icon(c.icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _EndPanel extends StatelessWidget {
  final bool isWin;
  final int score;
  final bool isDark;
  final String primaryLabel;
  final bool isLastLevel;
  final VoidCallback onPlayAgain;
  final VoidCallback onNextLevel;

  const _EndPanel({
    required this.isWin,
    required this.score,
    required this.isDark,
    required this.primaryLabel,
    required this.isLastLevel,
    required this.onPlayAgain,
    required this.onNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A1F3D)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC407A).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            primaryLabel,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A152A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.isSinhala ? 'ලකුණු: $score' : 'Score: $score',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFFEC407A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onPlayAgain,
                icon: const Icon(Icons.replay_rounded),
                label: Text(
                  s.isSinhala ? 'නැවත කරන්න' : 'Replay',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEC407A),
                  side: const BorderSide(color: Color(0xFFEC407A)),
                ),
              ),
              if (isWin && !isLastLevel) ...[
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onNextLevel,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: Text(
                    s.isSinhala ? 'ඊළඟ මට්ටම' : 'Next Level',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEC407A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              Icon(icon, color: color, size: 15),
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
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A152A),
            ),
          ),
        ],
      ),
    );
  }
}