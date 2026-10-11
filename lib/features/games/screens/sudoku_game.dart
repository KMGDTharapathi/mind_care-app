import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/services/game_audio_service.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';
import 'package:mind_care_app/data/local/preferences_service.dart';
import '../logic/sudoku_logic.dart';
import '../widgets/game_exit_dialog.dart';

class SudokuGame extends StatefulWidget {
  const SudokuGame({super.key});
  @override
  State<SudokuGame> createState() => _SudokuGameState();
}

class _SudokuGameState extends State<SudokuGame> {
  final _sudoku = Sudoku();
  bool _started = false;
  bool _solved = false;

  late SudokuPuzzle _puzzle;
  late List<List<int>> _grid;
  late List<List<bool>> _given;

  int _seconds = 0;
  Timer? _timer;
  List<int>? _selected;
  int _best = 0;

  static const _clueFor = {'easy': 40, 'medium': 32, 'hard': 26};

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
    final best = await PreferencesService.getGameSudokuBest();
    if (!mounted) return;
    setState(() => _best = best);
  }

  void _start(int clues) {
    _puzzle = _sudoku.generate(clues: clues);
    _grid = [for (final row in _puzzle.puzzle) List.of(row)];
    _given = [
      for (final row in _puzzle.puzzle) [for (final v in row) v != 0],
    ];
    setState(() {
      _started = true;
      _solved = false;
      _selected = null;
      _seconds = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_solved) setState(() => _seconds++);
    });
  }

  void _select(int r, int c) {
    if (_solved) return;
    GameAudio.instance.play(GameSfx.tap);
    setState(() => _selected = [r, c]);
  }

  void _input(int value) {
    final sel = _selected;
    if (sel == null || _solved) return;
    final r = sel[0];
    final c = sel[1];
    if (_given[r][c]) return;

    setState(() => _grid[r][c] = value);
    if (value == 0) return;

    if (_sudoku.isValidPlacement(_grid, r, c, value)) {
      GameAudio.instance.play(GameSfx.correct);
      HapticFeedback.selectionClick();
      if (_sudoku.isSolved(_grid)) _finish();
    } else {
      GameAudio.instance.play(GameSfx.wrong);
      HapticFeedback.mediumImpact();
    }
  }

  void _hint() {
    if (_solved) return;
    final blanks = <List<int>>[];
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (_grid[r][c] != _puzzle.solution[r][c]) blanks.add([r, c]);
      }
    }
    if (blanks.isEmpty) return;
    blanks.shuffle();
    final p = blanks.first;
    setState(() {
      _grid[p[0]][p[1]] = _puzzle.solution[p[0]][p[1]];
      _selected = p;
    });
    GameAudio.instance.play(GameSfx.correct);
    if (_sudoku.isSolved(_grid)) _finish();
  }

  void _finish() {
    _timer?.cancel();
    _solved = true;
    GameAudio.instance.play(GameSfx.win);
    HapticFeedback.heavyImpact();
    if (_best == 0 || _seconds < _best) _best = _seconds;
    unawaited(PreferencesService.setGameSudokuBest(_seconds));
    setState(() {});
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
            '🧠 ${LanguageProvider.of(context).gameSudokuTitle}'
            '${_started ? '  ⏱ ${_fmt(_seconds)}' : ''}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            if (_started && !_solved)
              IconButton(
                tooltip: LanguageProvider.of(context).hint,
                icon: const Icon(Icons.lightbulb_outline_rounded),
                onPressed: _hint,
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
            const Text('🧠', style: TextStyle(fontSize: 90)),
            const SizedBox(height: 16),
            Text(
              s.gameSudokuTitle,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.sudokuInstructions,
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
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _diffBtn(s.easy, 'easy'),
                _diffBtn(s.medium, 'medium'),
                _diffBtn(s.hard, 'hard'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _diffBtn(String label, String key) {
    return ElevatedButton(
      onPressed: () => _start(_clueFor[key]!),
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
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AspectRatio(aspectRatio: 1, child: _buildBoard()),
            ),
          ),
        ),
        if (_solved)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                Text(
                  s.solved,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                if (_best == _seconds)
                  Text(
                    s.newBest,
                    style: const TextStyle(
                      color: Color(0xFF5BA8A0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        _buildKeypad(),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, box) {
        final cell = box.maxWidth / 9;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF5BA8A0), width: 2),
          ),
          child: Stack(
            children: [
              for (var r = 0; r < 9; r++)
                for (var c = 0; c < 9; c++)
                  Positioned(
                    left: c * cell,
                    top: r * cell,
                    width: cell,
                    height: cell,
                    child: _buildCell(r, c),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCell(int r, int c) {
    final v = _grid[r][c];
    final isGiven = _given[r][c];
    final selected = _selected != null &&
        _selected![0] == r &&
        _selected![1] == c;
    final conflict =
        v != 0 && !_sudoku.isValidPlacement(_grid, r, c, v);

    Color bg = Colors.transparent;
    if (selected) bg = const Color(0xFF5BA8A0).withValues(alpha: 0.25);
    if (_selected != null &&
        !selected &&
        (_selected![0] == r ||
            _selected![1] == c ||
            (_selected![0] ~/ 3 == r ~/ 3 && _selected![1] ~/ 3 == c ~/ 3))) {
      bg = const Color(0xFF5BA8A0).withValues(alpha: 0.08);
    }

    Color text = isGiven ? const Color(0xFF1A3333) : const Color(0xFF00796B);
    if (conflict) text = const Color(0xFFD32F2F);

    final rightBorder = (c + 1) % 3 == 0 && c != 8;
    final bottomBorder = (r + 1) % 3 == 0 && r != 8;

    return GestureDetector(
      onTap: () => _select(r, c),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            right: rightBorder
                ? const BorderSide(color: Color(0xFF388E3C), width: 2)
                : BorderSide(color: Colors.grey.shade300),
            bottom: bottomBorder
                ? const BorderSide(color: Color(0xFF388E3C), width: 2)
                : BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Center(
          child: Text(
            v == 0 ? '' : '$v',
            style: TextStyle(
              fontSize: 20,
              fontWeight: isGiven ? FontWeight.bold : FontWeight.w500,
              color: text,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 1; i <= 9; i++) _numberBtn(i),
          _eraseBtn(),
        ],
      ),
    );
  }

  Widget _numberBtn(int value) {
    final sel = _selected;
    final used = sel != null &&
        _grid[sel[0]][sel[1]] == value;
    return GestureDetector(
      onTap: () => _input(value),
      child: Container(
        width: 54,
        height: 48,
        decoration: BoxDecoration(
          color: used
              ? const Color(0xFF5BA8A0)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF5BA8A0).withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: used ? Colors.white : const Color(0xFF00796B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _eraseBtn() {
    return GestureDetector(
      onTap: () => _input(0),
      child: Container(
        width: 54,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF5BA8A0).withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: const Icon(Icons.backspace_outlined, color: Color(0xFF00796B)),
      ),
    );
  }
}

String _fmt(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
