import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';
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
  int? _firstIdx;
  List<_Card> _cards = [];
  bool _checking = false;
  int _level = 1;

  static const _emojis = ['🌸', '🌿', '🦋', '🌈', '⭐', '🍀', '🌙', '🌺', '🐢', '🦄', '🎵', '💎'];

  void _initLevel(int lvl) {
    _level = lvl;
    final pairs = min(4 + lvl * 2, 12);
    final pool = _emojis.sublist(0, pairs);
    final all = [...pool, ...pool]..shuffle(_rng);
    _cards = List.generate(all.length, (i) => _Card(i, all[i]));
    _firstIdx = null;
    _checking = false;
    _moves = 0;
  }

  @override
  void initState() {
    super.initState();
    _initLevel(1);
  }

  void _onTap(int idx) {
    if (_checking) return;
    final card = _cards[idx];
    if (card.matched || card.flipped) return;

    setState(() => card.flipped = true);

    if (_firstIdx == null) {
      _firstIdx = idx;
    } else {
      _moves++;
      _checking = true;
      final first = _cards[_firstIdx!];
      if (first.emoji == card.emoji) {
        first.matched = true;
        card.matched = true;
        _score += 20;
        _firstIdx = null;
        _checking = false;
        if (_cards.every((c) => c.matched)) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) setState(() => _initLevel(_level + 1));
          });
        }
      } else {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              first.flipped = false;
              card.flipped = false;
              _firstIdx = null;
              _checking = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cols = _level <= 2 ? 4 : 4;
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
          title: Text('🧩 Pattern Match  Lv.$_level',
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
            child: _started ? _buildGame(cols) : _buildIntro(),
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
            Text(s.gamePatternTitle, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            const SizedBox(height: 12),
            Text(s.patternInstructions,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF388E3C), height: 1.6)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => setState(() { _started = true; _initLevel(1); }),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5BA8A0), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: Text('${s.play} 🧩', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGame(int cols) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${LanguageProvider.of(context).moves}: $_moves', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              Text('${LanguageProvider.of(context).pairs}: ${_cards.where((c) => c.matched).length ~/ 2} / ${_cards.length ~/ 2}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _cards.length,
              itemBuilder: (_, i) => _buildCard(_cards[i], i),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(_Card card, int idx) {
    return GestureDetector(
      onTap: () => _onTap(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: card.matched
              ? const Color(0xFFA5D6A7)
              : card.flipped
                  ? Colors.white
                  : const Color(0xFF5BA8A0),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
          border: card.matched
              ? Border.all(color: const Color(0xFF43A047), width: 2)
              : null,
        ),
        child: Center(
          child: card.flipped || card.matched
              ? Text(card.emoji, style: const TextStyle(fontSize: 32))
              : const Text('?', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _Card {
  final int id;
  final String emoji;
  bool flipped;
  bool matched;
  _Card(this.id, this.emoji, {this.flipped = false, this.matched = false});
}
