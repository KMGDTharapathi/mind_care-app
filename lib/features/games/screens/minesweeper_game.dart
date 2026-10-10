import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/services/game_audio_service.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import '../logic/minesweeper_logic.dart';
import '../widgets/game_exit_dialog.dart';

class _Difficulty {
  final String key;
  final int rows, cols, mines;
  const _Difficulty(this.key, this.rows, this.cols, this.mines);
}

class MinesweeperGame extends StatefulWidget {
  const MinesweeperGame({super.key});
  @override
  State<MinesweeperGame> createState() => _MinesweeperGameState();
}

class _MinesweeperGameState extends State<MinesweeperGame> {
  static const _diffs = [
    _Difficulty('easy', 9, 9, 10),
    _Difficulty('medium', 9, 9, 18),
    _Difficulty('hard', 9, 9, 28),
  ];

  bool _started = false;
  late Minesweeper _game;
  bool _flagMode = false;
  int _seconds = 0;
  Timer? _timer;
  int _best = 0;

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final best = await PreferencesService.getGameMinesBest();
    if (!mounted) return;
    setState(() => _best = best);
  }

  void _start(_Difficulty d) {
    _game = Minesweeper(rows: d.rows, cols: d.cols, totalMines: d.mines);
    setState(() {
      _started = true;
      _flagMode = false;
      _seconds = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_game.isOver) setState(() => _seconds++);
    });
  }

  void _tap(int r, int c) {
    if (_game.isOver) return;
    final cell = _game.grid[r][c];
    if (_flagMode && !cell.revealed) {
      _toggleFlag(r, c);
      return;
    }
    if (cell.flagged) return;
    final before = _game.isOver;
    setState(() => _game.reveal(r, c));
    if (_game.exploded) {
      GameAudio.instance.play(GameSfx.crash);
      HapticFeedback.heavyImpact();
      _finish();
    } else if (_game.won) {
      GameAudio.instance.play(GameSfx.win);
      HapticFeedback.heavyImpact();
      _finish();
    } else if (!before) {
      GameAudio.instance.play(GameSfx.pop);
      HapticFeedback.selectionClick();
    }
  }

  void _toggleFlag(int r, int c) {
    if (_game.isOver) return;
    final cell = _game.grid[r][c];
    if (cell.revealed) return;
    GameAudio.instance.play(GameSfx.tap);
    HapticFeedback.selectionClick();
    setState(() => _game.toggleFlag(r, c));
  }

  void _finish() {
    _timer?.cancel();
    if (_game.won && (_best == 0 || _seconds < _best)) {
      _best = _seconds;
      unawaited(PreferencesService.setGameMinesBest(_seconds));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showGameExitDialog(context);
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F5E9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF5BA8A0),
          foregroundColor: Colors.white,
          title: Text(
            '🔎 ${s.gameMinesTitle}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            if (_started && !_game.isOver)
              IconButton(
                tooltip: _flagMode ? s.revealMode : s.flagMode,
                icon: Icon(
                  _flagMode
                      ? Icons.flag_rounded
                      : Icons.touch_app_rounded,
                ),
                onPressed: () => setState(() => _flagMode = !_flagMode),
              ),
          ],
        ),
        body: LeafBackground(
          child: SafeArea(child: _started ? _buildGame() : _buildIntro()),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    final s = LanguageProvider.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔎', style: TextStyle(fontSize: 90)),
            const SizedBox(height: 16),
            Text(
              s.gameMinesTitle,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.minesInstructions,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF388E3C),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${s.best}: ${_best == 0 ? '--:--' : _fmt(_best)}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5BA8A0),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              s.difficulty,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _diffBtn(s.easy, _diffs[0]),
                const SizedBox(width: 10),
                _diffBtn(s.medium, _diffs[1]),
                const SizedBox(width: 10),
                _diffBtn(s.hard, _diffs[2]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _diffBtn(String label, _Difficulty d) {
    return ElevatedButton(
      onPressed: () => _start(d),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5BA8A0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildGame() {
    final s = LanguageProvider.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat('💣 ${s.mines}', '${_game.minesLeft}'),
              _stat('⏱ ${s.time}', _fmt(_seconds)),
              _stat(s.best, _best == 0 ? '--:--' : _fmt(_best)),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AspectRatio(
                aspectRatio: _game.cols / _game.rows,
                child: _buildBoard(),
              ),
            ),
          ),
        ),
        if (_game.isOver) _buildResult(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black45,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, box) {
        final cellW = box.maxWidth / _game.cols;
        final cellH = box.maxHeight / _game.rows;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF5BA8A0).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              for (var r = 0; r < _game.rows; r++)
                for (var c = 0; c < _game.cols; c++)
                  Positioned(
                    left: c * cellW,
                    top: r * cellH,
                    width: cellW,
                    height: cellH,
                    child: _buildCell(r, c),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCell(int r, int c) {
    final cell = _game.grid[r][c];
    final showMine = _game.isOver && cell.mine && !cell.flagged;

    Color bg;
    if (cell.revealed) {
      bg = cell.mine
          ? const Color(0xFFE57373)
          : Colors.white.withValues(alpha: 0.92);
    } else {
      bg = const Color(0xFF4DB6AC);
    }

    Widget? child;
    if (showMine) {
      child = const Center(child: Text('💣', style: TextStyle(fontSize: 14)));
    } else if (cell.flagged && !cell.revealed) {
      child = const Center(child: Text('🚩', style: TextStyle(fontSize: 13)));
    } else if (cell.revealed && cell.adjacent > 0) {
      child = Center(
        child: Text(
          '${cell.adjacent}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: _numColor(cell.adjacent),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _tap(r, c),
      onLongPress: () => _toggleFlag(r, c),
      child: Container(
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(3),
        ),
        child: child,
      ),
    );
  }


  Widget _buildResult() {
    final s = LanguageProvider.of(context);
    final won = _game.won;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(won ? '🎉' : '💥', style: const TextStyle(fontSize: 40)),
            Text(
              won ? s.youWin : s.gameOver,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            Text(
              '${s.time}: ${_fmt(_seconds)}',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _start(_diffs.firstWhere(
                (d) => d.rows == _game.rows && d.mines == _game.totalMines,
                orElse: () => _diffs.first,
              )),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5BA8A0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(s.playAgain),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

Color _numColor(int n) {
  switch (n) {
    case 1:
      return const Color(0xFF1976D2);
    case 2:
      return const Color(0xFF388E3C);
    case 3:
      return const Color(0xFFD32F2F);
    case 4:
      return const Color(0xFF7B1FA2);
    case 5:
      return const Color(0xFFF57C00);
    case 6:
      return const Color(0xFF0097A7);
    case 7:
      return const Color(0xFF5D4037);
    default:
      return const Color(0xFF424242);
  }
}
