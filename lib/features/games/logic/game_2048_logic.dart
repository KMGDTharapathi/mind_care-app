import 'dart:math';

/// Direction a swipe moves the tiles.
enum SwipeDir { up, down, left, right }

/// Pure, testable 2048 engine — no Flutter dependency.
///
/// The board is a `size x size` grid where `0` means empty and every other
/// value is a power of two. Call [move] with a direction; it returns whether
/// anything actually changed.
class Game2048 {
  final int size;
  final Random _rng;

  late List<List<int>> board;
  int score = 0;
  bool won = false;
  bool over = false;

  final List<List<List<int>>> _history = [];
  final List<int> _scoreHistory = [];
  static const int _maxUndo = 20;

  Game2048({this.size = 4, int? seed}) : _rng = Random(seed) {
    _freshBoard();
    _spawn();
    _spawn();
  }

  void _freshBoard() {
    board = List.generate(size, (_) => List.filled(size, 0));
    score = 0;
    won = false;
    over = false;
    _history.clear();
    _scoreHistory.clear();
  }

  /// Restarts the game from scratch.
  void reset() {
    _freshBoard();
    _spawn();
    _spawn();
  }

  bool get canUndo => _history.isNotEmpty;

  int get maxTile {
    var m = 0;
    for (final row in board) {
      for (final v in row) {
        if (v > m) m = v;
      }
    }
    return m;
  }

  /// Applies a swipe. Returns true when the board changed.
  bool move(SwipeDir dir) {
    if (over) return false;
    final before = _snapshot();
    final beforeScore = score;

    for (var i = 0; i < size; i++) {
      final line = _collapse(_readLine(dir, i));
      _writeLine(dir, i, line);
    }

    if (_same(before, board)) return false;

    _history.add(before);
    _scoreHistory.add(beforeScore);
    if (_history.length > _maxUndo) {
      _history.removeAt(0);
      _scoreHistory.removeAt(0);
    }

    _spawn();
    if (maxTile >= 2048) won = true;
    if (!_canMove()) over = true;
    return true;
  }

  bool undo() {
    if (_history.isEmpty) return false;
    board = _history.removeLast();
    score = _scoreHistory.removeLast();
    over = false;
    return true;
  }

  // ── internals ──────────────────────────────────────────────────────────────

  List<int> _readLine(SwipeDir dir, int i) {
    switch (dir) {
      case SwipeDir.left:
        return List.of(board[i]);
      case SwipeDir.right:
        return board[i].reversed.toList();
      case SwipeDir.up:
        return [for (var r = 0; r < size; r++) board[r][i]];
      case SwipeDir.down:
        return [for (var r = size - 1; r >= 0; r--) board[r][i]];
    }
  }

  void _writeLine(SwipeDir dir, int i, List<int> line) {
    switch (dir) {
      case SwipeDir.left:
        board[i] = List.of(line);
      case SwipeDir.right:
        board[i] = line.reversed.toList();
      case SwipeDir.up:
        for (var r = 0; r < size; r++) {
          board[r][i] = line[r];
        }
      case SwipeDir.down:
        for (var r = 0; r < size; r++) {
          board[size - 1 - r][i] = line[r];
        }
    }
  }

  /// Slides a line toward index 0, merging equal neighbours once.
  List<int> _collapse(List<int> line) {
    final vals = line.where((v) => v != 0).toList();
    final out = <int>[];
    for (var i = 0; i < vals.length; i++) {
      if (i + 1 < vals.length && vals[i] == vals[i + 1]) {
        final merged = vals[i] * 2;
        out.add(merged);
        score += merged;
        i++;
      } else {
        out.add(vals[i]);
      }
    }
    while (out.length < size) {
      out.add(0);
    }
    return out;
  }

  void _spawn() {
    final empty = <List<int>>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (board[r][c] == 0) empty.add([r, c]);
      }
    }
    if (empty.isEmpty) return;
    final p = empty[_rng.nextInt(empty.length)];
    board[p[0]][p[1]] = _rng.nextDouble() < 0.9 ? 2 : 4;
  }

  bool _canMove() {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (board[r][c] == 0) return true;
        if (c + 1 < size && board[r][c] == board[r][c + 1]) return true;
        if (r + 1 < size && board[r][c] == board[r + 1][c]) return true;
      }
    }
    return false;
  }

  List<List<int>> _snapshot() => [for (final row in board) List.of(row)];

  bool _same(List<List<int>> a, List<List<int>> b) {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (a[r][c] != b[r][c]) return false;
      }
    }
    return true;
  }
}
