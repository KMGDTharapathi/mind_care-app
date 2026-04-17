import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';
import '../widgets/game_exit_dialog.dart';

class AimDropGame extends StatefulWidget {
  const AimDropGame({super.key});
  @override
  State<AimDropGame> createState() => _AimDropGameState();
}

class _AimDropGameState extends State<AimDropGame> with SingleTickerProviderStateMixin {
  bool _started = false;
  bool _gameOver = false;
  int _score = 0;
  int _lives = 3;
  int _level = 1;
  int _round = 0;

  // Pendulum
  late AnimationController _pendulum;
  late Animation<double> _swingAnim;

  // Zones
  late List<_Zone> _zones;
  int _targetZoneIdx = 0;
  String _ballEmoji = '🟢';

  static const _ballEmojis = ['🟢', '🔵', '🔴', '🟡', '🟣'];
  static const _zoneColors = [
    Color(0xFFEF5350), Color(0xFF42A5F5), Color(0xFF66BB6A),
    Color(0xFFFFCA28), Color(0xFFAB47BC),
  ];

  @override
  void initState() {
    super.initState();
    _pendulum = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _swingAnim = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _pendulum, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _pendulum.dispose(); super.dispose(); }

  void _startGame() {
    setState(() {
      _started = true;
      _gameOver = false;
      _score = 0;
      _lives = 3;
      _level = 1;
      _round = 0;
    });
    _nextRound();
    _pendulum.repeat(reverse: true);
  }

  void _nextRound() {
    final rng = Random();
    final numZones = min(2 + _level, 5);
    _zones = List.generate(numZones, (i) => _Zone(i, _zoneColors[i]));
    _targetZoneIdx = rng.nextInt(numZones);
    _ballEmoji = _ballEmojis[_targetZoneIdx];
    // Speed up with level
    final ms = max(600, 1800 - (_level - 1) * 200);
    _pendulum.duration = Duration(milliseconds: ms);
    _pendulum.repeat(reverse: true);
  }

  void _drop() {
    if (_gameOver || !_started) return;
    _pendulum.stop();
    final swingVal = _swingAnim.value; // -1 to 1
    final size = MediaQuery.of(context).size;
    final zoneW = (size.width - 32) / _zones.length;
    // Map swing to x position
    final x = (swingVal + 1) / 2 * (size.width - 32);
    final zoneIdx = (x / zoneW).floor().clamp(0, _zones.length - 1);

    setState(() {
      _round++;
      if (zoneIdx == _targetZoneIdx) {
        _score += 20 + (_level * 5);
        if (_round % 3 == 0) _level++;
      } else {
        _lives--;
        if (_lives <= 0) { _gameOver = true; return; }
      }
      _nextRound();
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
          title: Text('🎯 Aim & Drop  Lv.$_level',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('Score: $_score',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
          ],
        ),
        body: LeafBackground(
          child: SafeArea(
            child: _started ? (_gameOver ? _buildGameOver() : _buildGame()) : _buildIntro(),
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
            const Text('🎯', style: TextStyle(fontSize: 90)),
            const SizedBox(height: 16),
            Text(s.gameAimTitle, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            const SizedBox(height: 12),
            Text(s.aimInstructions,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF388E3C), height: 1.6)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => setState(() => _startGame()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5BA8A0), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: Text('${s.gameAimTitle}! 🎯', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGame() {
    return GestureDetector(
      onTap: _drop,
      child: Column(
        children: [
          // Lives
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: List.generate(3, (i) =>
                    Text(i < _lives ? '❤️' : '🖤', style: const TextStyle(fontSize: 22)))),
                Text('${LanguageProvider.of(context).round}: $_round', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              ],
            ),
          ),
          // Target hint
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Drop into: ', style: TextStyle(fontSize: 14, color: Colors.black54)),                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: _zoneColors[_targetZoneIdx],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_ballEmoji, style: const TextStyle(fontSize: 22)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Pendulum
          Expanded(
            child: AnimatedBuilder(
              animation: _swingAnim,
              builder: (context, _) {
                final size = MediaQuery.of(context).size;
                final ballX = ((_swingAnim.value + 1) / 2) * (size.width - 64) + 16;
                return Stack(
                  children: [
                    // Rope
                    Positioned(
                      top: 0, left: size.width / 2 - 1,
                      child: Container(
                        width: 2,
                        height: 180,
                        color: const Color(0xFF5BA8A0).withOpacity(0.5),
                      ),
                    ),
                    // Ball
                    Positioned(
                      top: 140,
                      left: ballX - 24,
                      child: Text(_ballEmoji, style: const TextStyle(fontSize: 44)),
                    ),
                    // Tap hint
                    Positioned(
                      bottom: 20, left: 0, right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5BA8A0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(LanguageProvider.of(context).tapToDrop,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Zones
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: List.generate(_zones.length, (i) => Expanded(
                child: Container(
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _zones[i].color.withOpacity(i == _targetZoneIdx ? 1.0 : 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: i == _targetZoneIdx
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: Center(
                    child: Text(i == _targetZoneIdx ? '⬆️' : '',
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
              )),
            ),
          ),
        ],
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
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 72)),
            Text(s.gameOver, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            const SizedBox(height: 8),
            Text('${s.score}: $_score  |  ${s.round}: $_round',
                style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _startGame()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5BA8A0), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text('${s.playAgain} 🎯', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Zone {
  final int idx;
  final Color color;
  _Zone(this.idx, this.color);
}
