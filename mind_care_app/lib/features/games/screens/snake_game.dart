import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';
import '../widgets/game_exit_dialog.dart';
import '../widgets/game_assistant.dart';

enum _Dir { up, down, left, right }

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});
  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  static const int _cols = 16;
  static const int _rows = 20;

  List<Point<int>> _snake = [];
  _Dir _dir = _Dir.right;
  _Dir _nextDir = _Dir.right;
  Point<int> _food = const Point(5, 5);
  bool _running = false;
  bool _gameOver = false;
  int _score = 0;
  int _level = 1;
  Timer? _timer;
  final _rng = Random();
  bool _showHelp = true;

  static const _foodEmojis = ['🍎', '🍊', '🍋', '🍇', '🍓', '🫐', '🍑'];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _snake = [const Point(8, 10), const Point(7, 10), const Point(6, 10)];
    _dir = _Dir.right;
    _nextDir = _Dir.right;
    _score = 0;
    _level = 1;
    _gameOver = false;
    _running = true;
    _showHelp = true;
    _spawnFood();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    final ms = max(180, 350 - (_level - 1) * 30);
    _timer = Timer.periodic(Duration(milliseconds: ms), (_) => _tick());
  }

  void _tick() {
    if (!mounted || !_running) return;
    setState(() {
      _dir = _nextDir;
      final head = _snake.first;
      Point<int> newHead;
      switch (_dir) {
        case _Dir.up:
          newHead = Point(head.x, head.y - 1);
          break;
        case _Dir.down:
          newHead = Point(head.x, head.y + 1);
          break;
        case _Dir.left:
          newHead = Point(head.x - 1, head.y);
          break;
        case _Dir.right:
          newHead = Point(head.x + 1, head.y);
          break;
      }
      if (newHead.x < 0 ||
          newHead.x >= _cols ||
          newHead.y < 0 ||
          newHead.y >= _rows ||
          _snake.contains(newHead)) {
        _running = false;
        _gameOver = true;
        _timer?.cancel();
        return;
      }
      _snake.insert(0, newHead);
      if (newHead == _food) {
        _score += 10;
        _showHelp = false;
        if (_score % 50 == 0) {
          _level++;
          _startTimer();
        }
        _spawnFood();
      } else {
        _snake.removeLast();
      }
    });
  }

  void _spawnFood() {
    Point<int> p;
    do {
      p = Point(_rng.nextInt(_cols), _rng.nextInt(_rows));
    } while (_snake.contains(p));
    _food = p;
  }

  void _setDir(_Dir d) {
    if (_dir == _Dir.up && d == _Dir.down) return;
    if (_dir == _Dir.down && d == _Dir.up) return;
    if (_dir == _Dir.left && d == _Dir.right) return;
    if (_dir == _Dir.right && d == _Dir.left) return;
    _nextDir = d;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cell = (size.width - 32) / _cols;

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
            '🐍 Snake  Lv.$_level  Score:$_score',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        body: LeafBackground(
          child: SafeArea(
            child: _gameOver
                ? _buildGameOver()
                : !_running
                ? _buildIntro()
                : _buildGame(cell),
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
            const Text('🐍', style: TextStyle(fontSize: 90)),
            const SizedBox(height: 16),
            Text(
              s.gameSnakeTitle,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.snakeInstructions,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF388E3C),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => setState(() => _startGame()),
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
                '${s.start} 🐍',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGame(double cell) {
    return Column(
      children: [
        if (_showHelp)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              LanguageProvider.of(context).snakeHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF795548)),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AspectRatio(
              aspectRatio: _cols / _rows,
              child: CustomPaint(
                painter: _SnakePainter(
                  snake: _snake,
                  food: _food,
                  cols: _cols,
                  rows: _rows,
                  foodEmoji: _foodEmojis[_food.x % _foodEmojis.length],
                ),
              ),
            ),
          ),
        ),
        _buildControls(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildControls() {
    final s = LanguageProvider.of(context);
    const btnColor = Color(0xFF5BA8A0);
    return Column(
      children: [
        _arrowBtn(
          Icons.keyboard_arrow_up_rounded,
          () => _setDir(_Dir.up),
          btnColor,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _arrowBtn(
              Icons.keyboard_arrow_left_rounded,
              () => _setDir(_Dir.left),
              btnColor,
            ),
            const SizedBox(width: 48),
            _arrowBtn(
              Icons.keyboard_arrow_right_rounded,
              () => _setDir(_Dir.right),
              btnColor,
            ),
          ],
        ),
        _arrowBtn(
          Icons.keyboard_arrow_down_rounded,
          () => _setDir(_Dir.down),
          btnColor,
        ),
        const SizedBox(height: 4),
        GameAssistant(
          emoji: '🧠',
          title: s.gameSnakeTitle,
          tips: s.snakeTips,
          accentColor: btnColor,
        ),
      ],
    );
  }

  Widget _arrowBtn(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }

  Widget _buildGameOver() {
    final s = LanguageProvider.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💀', style: TextStyle(fontSize: 72)),
            Text(
              s.gameOver,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${s.score}: $_score  |  ${s.level}: $_level',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _startGame()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5BA8A0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: Text(
                '${s.playAgain} 🐍',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnakePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int> food;
  final int cols, rows;
  final String foodEmoji;
  _SnakePainter({
    required this.snake,
    required this.food,
    required this.cols,
    required this.rows,
    required this.foodEmoji,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / cols;
    final ch = size.height / rows;
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1B5E20).withValues(alpha: 0.9),
    );
    // Grid
    final gp = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    for (int c = 0; c <= cols; c++) {
      canvas.drawLine(Offset(c * cw, 0), Offset(c * cw, size.height), gp);
    }
    for (int r = 0; r <= rows; r++) {
      canvas.drawLine(Offset(0, r * ch), Offset(size.width, r * ch), gp);
    }
    // Snake
    for (int i = 0; i < snake.length; i++) {
      final s = snake[i];
      final isHead = i == 0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s.x * cw + 1, s.y * ch + 1, cw - 2, ch - 2),
          const Radius.circular(4),
        ),
        Paint()
          ..color = isHead ? const Color(0xFF76FF03) : const Color(0xFF43A047),
      );
    }
    // Food
    final tp = TextPainter(
      text: TextSpan(
        text: foodEmoji,
        style: TextStyle(fontSize: cw * 0.7),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        food.x * cw + (cw - tp.width) / 2,
        food.y * ch + (ch - tp.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_SnakePainter o) => true;
}
