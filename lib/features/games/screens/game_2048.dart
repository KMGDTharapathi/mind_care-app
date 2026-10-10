import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/services/game_audio_service.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import '../logic/game_2048_logic.dart';
import '../widgets/game_exit_dialog.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});
  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  late Game2048 _game;
  bool _started = false;
  bool _bestBeaten = false;
  int _best = 0;

  @override
  void initState() {
    super.initState();
    _game = Game2048();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final best = await PreferencesService.getGame2048Best();
    if (!mounted) return;
    setState(() => _best = best);
  }

  void _start() {
    setState(() {
      _game = Game2048();
      _started = true;
      _bestBeaten = false;
    });
  }

  void _move(SwipeDir dir) {
    if (_game.over) return;
    final changed = _game.move(dir);
    if (!changed) {
      GameAudio.instance.play(GameSfx.bump);
      return;
    }
    GameAudio.instance.play(GameSfx.slide);
    HapticFeedback.selectionClick();
    if (_game.score > _best) {
      _best = _game.score;
      _bestBeaten = true;
    }
    if (_game.won) {
      GameAudio.instance.play(GameSfx.win);
      HapticFeedback.heavyImpact();
    } else if (_game.over) {
      GameAudio.instance.play(GameSfx.lose);
      HapticFeedback.heavyImpact();
    }
    if (_game.over || _game.won) {
      unawaited(PreferencesService.setGame2048Best(_game.score));
    }
    setState(() {});
  }

  void _undo() {
    if (!_game.canUndo) return;
    GameAudio.instance.play(GameSfx.bump);
    setState(() {
      _game.undo();
      _bestBeaten = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text(
            '🔢 2048',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            if (_started && !_game.over)
              IconButton(
                tooltip: LanguageProvider.of(context).undo,
                icon: const Icon(Icons.undo_rounded),
                onPressed: _game.canUndo ? _undo : null,
              ),
          ],
        ),
        body: LeafBackground(
          child: SafeArea(
            child: _started ? _buildGame() : _buildIntro(),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    final s = LanguageProvider.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔢', style: TextStyle(fontSize: 90)),
            const SizedBox(height: 16),
            Text(
              s.game2048Title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.game2048Instructions,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF388E3C),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${s.best}: $_best',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5BA8A0),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5BA8A0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
              ),
              child: Text(
                '${s.play} 🔢',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
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
            children: [
              _statBox(s.score, '${_game.score}'),
              const SizedBox(width: 10),
              _statBox(s.best, '$_best', highlight: _bestBeaten),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: s.restart,
                onPressed: _start,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: GestureDetector(
              onPanEnd: (d) {
                final v = d.velocity.pixelsPerSecond;
                if (v.dx.abs() < 20 && v.dy.abs() < 20) return;
                if (v.dx.abs() > v.dy.abs()) {
                  _move(v.dx > 0 ? SwipeDir.right : SwipeDir.left);
                } else {
                  _move(v.dy > 0 ? SwipeDir.down : SwipeDir.up);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBBADA0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        _buildTiles(),
                        if (_game.over || _game.won)
                          _buildOverlay(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildArrows(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTiles() {
    final n = _game.size;
    return LayoutBuilder(
      builder: (context, box) {
        final gap = 6.0;
        final cell = (box.maxWidth - gap * (n + 1)) / n;
        final children = <Widget>[];
        for (var r = 0; r < n; r++) {
          for (var c = 0; c < n; c++) {
            final v = _game.board[r][c];
            final left = gap + c * (cell + gap);
            final top = gap + r * (cell + gap);
            children.add(
              Positioned(
                left: left,
                top: top,
                width: cell,
                height: cell,
                child: v == 0
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      )
                    : AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        decoration: BoxDecoration(
                          color: _tileColor(v),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: FittedBox(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                '$v',
                                style: TextStyle(
                                  fontSize: v >= 1024 ? 20 : 26,
                                  fontWeight: FontWeight.bold,
                                  color: _tileTextColor(v),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            );
          }
        }
        return Stack(children: children);
      },
    );
  }

  Widget _buildOverlay() {
    final s = LanguageProvider.of(context);
    final win = _game.won;
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(win ? '🏆' : '😔', style: const TextStyle(fontSize: 56)),
            Text(
              win ? s.youWin : s.gameOver,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 6),
            if (_bestBeaten)
              Text(
                s.newBest,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5BA8A0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              '${s.score}: ${_game.score}',
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5BA8A0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(s.playAgain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrows() {
    const color = Color(0xFF5BA8A0);
    return Column(
      children: [
        _arrow(Icons.keyboard_arrow_up_rounded, () => _move(SwipeDir.up), color),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _arrow(
              Icons.keyboard_arrow_left_rounded,
              () => _move(SwipeDir.left),
              color,
            ),
            const SizedBox(width: 40),
            _arrow(
              Icons.keyboard_arrow_right_rounded,
              () => _move(SwipeDir.right),
              color,
            ),
          ],
        ),
        _arrow(
          Icons.keyboard_arrow_down_rounded,
          () => _move(SwipeDir.down),
          color,
        ),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  Widget _statBox(String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: const Color(0xFF5BA8A0), width: 2)
            : null,
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black45,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}

Color _tileColor(int v) {
  switch (v) {
    case 2:
      return const Color(0xFFEEE4DA);
    case 4:
      return const Color(0xFFEDE0C8);
    case 8:
      return const Color(0xFFF2B179);
    case 16:
      return const Color(0xFFF59563);
    case 32:
      return const Color(0xFFF67C5F);
    case 64:
      return const Color(0xFFF65E3B);
    case 128:
      return const Color(0xFFEDCF72);
    case 256:
      return const Color(0xFFEDCC61);
    case 512:
      return const Color(0xFFEDC850);
    case 1024:
      return const Color(0xFFEDC53F);
    case 2048:
      return const Color(0xFFEDC22E);
    default:
      return const Color(0xFF3C3A32);
  }
}

Color _tileTextColor(int v) =>
    v <= 4 ? const Color(0xFF776E65) : Colors.white;
