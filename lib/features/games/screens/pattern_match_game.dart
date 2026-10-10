import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/services/game_audio_service.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import '../widgets/game_exit_dialog.dart';

class PatternMatchGame extends StatefulWidget {
  const PatternMatchGame({super.key});
  @override
  State<PatternMatchGame> createState() => _PatternMatchGameState();
}

class _PatternMatchGameState extends State<PatternMatchGame> {
  final _rng = Random();
  bool _started = false;
  int _score = 0;
  int _moves = 0;
  int _combo = 0;
  int? _firstIdx;
  List<_Card> _cards = [];
  bool _checking = false;
  int _level = 1;
  int _seconds = 0;
  Timer? _timer;
  bool _levelComplete = false;
  int _levelStars = 0;

  int _best = 0;
  int _bestLevel = 1;

  static const _emojis = [
    '🌸', '🌿', '🦋', '🌈', '⭐', '🍀',
    '🌙', '🌺', '🐢', '🦄', '🎵', '💎',
  ];

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
    final best = await PreferencesService.getGameMemoryBest();
    final stars = await PreferencesService.getGameMemoryStars();
    final level = (int.tryParse(stars?.split(',').last ?? '') ?? 0);
    if (!mounted) return;
    setState(() {
      _best = best;
      if (level > 0) _bestLevel = max(1, level);
    });
  }

  int get _pairs => min(4 + (_level - 1) * 2, 12);

  int get _cols {
    final total = _cards.length;
    if (total <= 12) return 4;
    if (total <= 16) return 4;
    if (total <= 20) return 5;
    return 6;
  }

  void _initLevel(int lvl) {
    _level = lvl;
    final pairs = _pairs;
    final pool = _emojis.sublist(0, pairs);
    final all = [...pool, ...pool]..shuffle(_rng);
    _cards = List.generate(all.length, (i) => _Card(i, all[i]));
    _firstIdx = null;
    _checking = false;
    _moves = 0;
    _combo = 0;
    _seconds = 0;
    _levelComplete = false;
    _levelStars = 0;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _started && !_levelComplete) {
        setState(() => _seconds++);
      }
    });
  }

  void _startGame() {
    setState(() {
      _started = true;
      _score = 0;
      _initLevel(1);
    });
  }

  void _onTap(int idx) {
    if (_checking || _levelComplete) return;
    final card = _cards[idx];
    if (card.flipped || card.matched) return;

    GameAudio.instance.play(GameSfx.tap);
    HapticFeedback.selectionClick();

    setState(() {
      card.flipped = true;
      if (_firstIdx == null) {
        _firstIdx = idx;
        return;
      }
      _moves++;
      final first = _cards[_firstIdx!];
      if (first.emoji == card.emoji) {
        first.matched = true;
        card.matched = true;
        _combo++;
        _score += 10 + (_combo - 1) * 5;
        _firstIdx = null;
        GameAudio.instance.play(GameSfx.match, rate: 1 + _combo * 0.05);
        HapticFeedback.mediumImpact();
        if (_cards.every((c) => c.matched)) {
          _checking = true;
          Future.delayed(const Duration(milliseconds: 450), _finishLevel);
        }
      } else {
        _checking = true;
        _combo = 0;
        GameAudio.instance.play(GameSfx.wrong);
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 750), () {
          if (!mounted) return;
          setState(() {
            first.flipped = false;
            card.flipped = false;
            _firstIdx = null;
            _checking = false;
          });
        });
      }
    });
  }

  void _finishLevel() {
    final pairs = _cards.length ~/ 2;
    if (_moves <= (pairs * 1.6).round()) {
      _levelStars = 3;
    } else if (_moves <= (pairs * 2.3).round()) {
      _levelStars = 2;
    } else {
      _levelStars = 1;
    }
    _score += _levelStars * 50;
    if (_score > _best) _best = _score;
    if (_level > _bestLevel) _bestLevel = _level;
    GameAudio.instance.play(GameSfx.levelUp);
    HapticFeedback.mediumImpact();
    setState(() => _levelComplete = true);
    unawaited(PreferencesService.setGameMemoryBest(_best));
    unawaited(
      PreferencesService.setGameMemoryStars(
        [_bestLevel.toString(), _levelStars.toString()].join(','),
      ),
    );
  }

  void _continue() {
    setState(() => _initLevel(_level + 1));
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
            '🧩 ${LanguageProvider.of(context).gamePatternTitle}  '
            '${LanguageProvider.of(context).level} $_level',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${LanguageProvider.of(context).score}: $_score',
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
                ? (_levelComplete ? _buildLevelComplete() : _buildGame())
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
            const Text('🧩', style: TextStyle(fontSize: 90)),
            const SizedBox(height: 16),
            Text(
              s.gamePatternTitle,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.patternInstructions,
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
              onPressed: _startGame,
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
                '${s.play} 🧩',
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
    final s = LanguageProvider.of(context);
    final matchedPairs = _cards.where((c) => c.matched).length ~/ 2;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _chip('⏱ ${_fmt(_seconds)}'),
              _chip('${s.moves}: $_moves'),
              if (_combo > 1) _chip('🔥 ${s.combo} x$_combo'),
              _chip('${s.pairs}: $matchedPairs / ${_cards.length ~/ 2}'),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _cols,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _cards.length,
              itemBuilder: (_, i) => _FlipCard(
                showFace: _cards[i].flipped || _cards[i].matched,
                matched: _cards[i].matched,
                emoji: _cards[i].emoji,
                onTap: () => _onTap(i),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E7D32),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildLevelComplete() {
    final s = LanguageProvider.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            Text(
              '${s.level} $_level',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            _starRow(_levelStars),
            const SizedBox(height: 12),
            Text(
              '${s.time}: ${_fmt(_seconds)}  |  ${s.moves}: $_moves',
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            Text(
              '${s.score}: $_score  |  ${s.best}: $_best',
              style: const TextStyle(fontSize: 13, color: Color(0xFF5BA8A0)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _continue,
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
                '${s.nextLevel} →',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _starRow(int stars) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (i) => Icon(
          i < stars ? Icons.star_rounded : Icons.star_border_rounded,
          color: const Color(0xFFFFC107),
          size: 40,
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

class _FlipCard extends StatelessWidget {
  final bool showFace;
  final bool matched;
  final String emoji;
  final VoidCallback onTap;

  const _FlipCard({
    required this.showFace,
    required this.matched,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: showFace ? 1 : 0),
        duration: const Duration(milliseconds: 300),
        builder: (context, t, _) {
          final showEmoji = t >= 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(t * pi),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(showEmoji ? pi : 0),
              child: Container(
                decoration: BoxDecoration(
                  color: matched
                      ? const Color(0xFFA5D6A7)
                      : showEmoji
                      ? Colors.white
                      : const Color(0xFF5BA8A0),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                  border: matched
                      ? Border.all(color: const Color(0xFF43A047), width: 2)
                      : null,
                ),
                child: Center(
                  child: showEmoji
                      ? Text(emoji, style: const TextStyle(fontSize: 32))
                      : const Text(
                          '?',
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Card {
  final int id;
  final String emoji;
  bool flipped;
  bool matched;
  _Card(this.id, this.emoji) : matched = false, flipped = false;
}
