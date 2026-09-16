import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';
import '../widgets/game_exit_dialog.dart';

class StackBuilderGame extends StatefulWidget {
  const StackBuilderGame({super.key});
  @override
  State<StackBuilderGame> createState() => _StackBuilderGameState();
}

class _StackBuilderGameState extends State<StackBuilderGame>
    with SingleTickerProviderStateMixin {
  bool _started = false;
  bool _gameOver = false;
  int _score = 0;
  int _blocks = 0;
  List<_Block> _tower = [];
  late _Block _falling;
  double _fallingX = 0;
  double _speed = 2.0;
  bool _movingRight = true;
  Timer? _loop;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  bool _shaking = false;

  static const double _blockH = 38;
  static const double _baseW = 180;
  static const _labels = [
    'Work',
    'Rest',
    'Fun',
    'Sleep',
    'Friends',
    'Hobby',
    'Exercise',
    'Me Time',
  ];
  static const _colors = [
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFFFCA28),
    Color(0xFFAB47BC),
    Color(0xFF26C6DA),
    Color(0xFFFF9800),
    Color(0xFF8D6E63),
  ];

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnim = Tween<double>(
      begin: -8,
      end: 8,
    ).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
  }

  @override
  void dispose() {
    _loop?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _startGame() {
    final size = MediaQuery.of(context).size;
    final cx = size.width / 2 - _baseW / 2;
    setState(() {
      _started = true;
      _gameOver = false;
      _score = 0;
      _blocks = 0;
      _speed = 2.0;
      _movingRight = true;
      _tower = [
        _Block(
          x: cx,
          width: _baseW,
          label: LanguageProvider.of(context).foundation,
          color: const Color(0xFF5D4037),
        ),
      ];
      _falling = _newBlock(size.width);
      _fallingX = 0;
    });
    _loop?.cancel();
    _loop = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  List<String> _getLabels() {
    final s = LanguageProvider.of(context);
    return [
      s.stackWork,
      s.stackRest,
      s.stackFun,
      s.stackSleep,
      s.stackFriends,
      s.stackHobby,
      s.stackExercise,
      s.stackMeTime,
    ];
  }

  _Block _newBlock(double sw) {
    final labels = _getLabels();
    final idx = _tower.length % labels.length;
    return _Block(
      x: 0,
      width: _tower.last.width,
      label: labels[idx],
      color: _colors[idx % _colors.length],
    );
  }

  void _tick() {
    if (!mounted || _gameOver) return;
    final size = MediaQuery.of(context).size;
    setState(() {
      if (_movingRight) {
        _fallingX += _speed;
        if (_fallingX + _falling.width >= size.width - 16) _movingRight = false;
      } else {
        _fallingX -= _speed;
        if (_fallingX <= 16) _movingRight = true;
      }
      _falling = _Block(
        x: _fallingX,
        width: _falling.width,
        label: _falling.label,
        color: _falling.color,
      );
    });
  }

  void _drop() {
    if (_gameOver || !_started) return;
    final size = MediaQuery.of(context).size;
    final prev = _tower.last;
    final overlap = _calcOverlap(_fallingX, _falling.width, prev.x, prev.width);

    if (overlap <= 0) {
      _endGame();
      return;
    }

    final newX = max(_fallingX, prev.x);
    final newW = overlap;

    setState(() {
      _tower.add(
        _Block(
          x: newX,
          width: newW,
          label: _falling.label,
          color: _falling.color,
        ),
      );
      _blocks++;
      _score += (newW / _baseW * 20).round();
      _speed = min(7.0, _speed + 0.12);
      if (newW < _baseW * 0.45) {
        _shaking = true;
        _shakeCtrl.forward(from: 0).then((_) {
          _shakeCtrl.reverse();
        });
      }
      _falling = _newBlock(size.width);
      _fallingX = 0;
      _movingRight = true;
    });
  }

  double _calcOverlap(double ax, double aw, double bx, double bw) {
    return max(0, min(ax + aw, bx + bw) - max(ax, bx));
  }

  void _endGame() {
    _loop?.cancel();
    setState(() => _gameOver = true);
  }

  double get _towerBaseY {
    final size = MediaQuery.of(context).size;
    return size.height * 0.72;
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
          title: Text(
            '🏗️ Stack Builder  Blocks:$_blocks',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Score: $_score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: LeafBackground(
          child: SafeArea(
            child: _started
                ? (_gameOver ? _buildGameOver() : _buildGame())
                : _buildIntro(),
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
            const Text('🏗️', style: TextStyle(fontSize: 90)),
            const SizedBox(height: 16),
            Text(
              s.gameStackTitle,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.stackInstructions,
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
                '${s.gameStackTitle}! 🏗️',
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

  Widget _buildGame() {
    final baseY = _towerBaseY;
    return GestureDetector(
      onTap: _drop,
      child: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(_shaking ? _shakeAnim.value : 0, 0),
          child: child,
        ),
        child: Stack(
          children: [
            // Tower blocks (bottom up)
            for (int i = 0; i < _tower.length; i++)
              Positioned(
                left: _tower[i].x,
                top: baseY - i * (_blockH + 3),
                child: Container(
                  width: _tower[i].width,
                  height: _blockH,
                  decoration: BoxDecoration(
                    color: _tower[i].color,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _tower[i].color.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _tower[i].label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            // Falling block
            Positioned(
              left: _fallingX,
              top: baseY - _tower.length * (_blockH + 3) - _blockH - 8,
              child: Container(
                width: _falling.width,
                height: _blockH,
                decoration: BoxDecoration(
                  color: _falling.color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _falling.color.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _falling.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            // Tap button
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5BA8A0),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5BA8A0).withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    LanguageProvider.of(context).tapToDrop,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    final s = LanguageProvider.of(context);
    final msg = _blocks >= 15
        ? s.masterBuilder
        : _blocks >= 8
        ? s.greatStack
        : s.towerFellMsg;
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
            const Text('🏗️💥', style: TextStyle(fontSize: 72)),
            Text(
              s.towerFell,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF388E3C),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${s.blocks}: $_blocks  |  ${s.score}: $_score',
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
                '${s.buildAgain} 🏗️',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Block {
  final double x, width;
  final String label;
  final Color color;
  _Block({
    required this.x,
    required this.width,
    required this.label,
    required this.color,
  });
}
