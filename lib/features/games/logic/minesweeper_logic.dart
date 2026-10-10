import 'dart:math';

/// One cell of a Minesweeper board.
class MineCell {
  bool mine = false;
  bool revealed = false;
  bool flagged = false;
  int adjacent = 0;
}

/// Pure, testable Minesweeper engine — no Flutter dependency.
///
/// Mines are placed only after the first reveal so that the first tap is
/// always safe (the tapped cell and its neighbours are never mined).
class Minesweeper {
  final int rows;
  final int cols;
  final int totalMines;
  final Random _rng;

  late List<List<MineCell>> grid;
  bool generated = false;
  bool exploded = false;
  bool won = false;

  Minesweeper({
    this.rows = 9,
    this.cols = 9,
    required this.totalMines,
    int? seed,
  }) : _rng = Random(seed) {
    _resetGrid();
  }

  void _resetGrid() {
    grid = List.generate(
      rows,
      (_) => List.generate(cols, (_) => MineCell()),
    );
    generated = false;
    exploded = false;
    won = false;
  }

  void reset() => _resetGrid();

  bool get isOver => won || exploded;

  int get flagsUsed {
    var n = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell.flagged) n++;
      }
    }
    return n;
  }

  int get minesLeft => totalMines - flagsUsed;

  /// Reveals (r, c). The very first call also places the mines.
  void reveal(int r, int c) {
    if (isOver) return;
    if (r < 0 || r >= rows || c < 0 || c >= cols) return;
    if (!generated) _placeMines(r, c);

    final cell = grid[r][c];
    if (cell.revealed || cell.flagged) return;

    if (cell.mine) {
      cell.revealed = true;
      exploded = true;
      return;
    }

    _floodReveal(r, c);
    _checkWin();
  }

  void toggleFlag(int r, int c) {
    if (isOver) return;
    if (r < 0 || r >= rows || c < 0 || c >= cols) return;
    final cell = grid[r][c];
    if (cell.revealed) return;
    cell.flagged = !cell.flagged;
  }

  void _placeMines(int safeR, int safeC) {
    final banned = <String>{};
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final r = safeR + dr;
        final c = safeC + dc;
        if (r >= 0 && r < rows && c >= 0 && c < cols) banned.add('$r,$c');
      }
    }

    final spots = <List<int>>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (!banned.contains('$r,$c')) spots.add([r, c]);
      }
    }
    spots.shuffle(_rng);
    final n = min(totalMines, spots.length);
    for (var i = 0; i < n; i++) {
      grid[spots[i][0]][spots[i][1]].mine = true;
    }

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        var count = 0;
        for (var dr = -1; dr <= 1; dr++) {
          for (var dc = -1; dc <= 1; dc++) {
            final nr = r + dr;
            final nc = c + dc;
            if (nr >= 0 &&
                nr < rows &&
                nc >= 0 &&
                nc < cols &&
                grid[nr][nc].mine) {
              count++;
            }
          }
        }
        grid[r][c].adjacent = count;
      }
    }
    generated = true;
  }

  void _floodReveal(int r, int c) {
    final stack = <List<int>>[
      [r, c],
    ];
    while (stack.isNotEmpty) {
      final p = stack.removeLast();
      final rr = p[0];
      final cc = p[1];
      if (rr < 0 || rr >= rows || cc < 0 || cc >= cols) continue;
      final cell = grid[rr][cc];
      if (cell.revealed || cell.flagged || cell.mine) continue;
      cell.revealed = true;
      if (cell.adjacent == 0) {
        for (var dr = -1; dr <= 1; dr++) {
          for (var dc = -1; dc <= 1; dc++) {
            if (dr != 0 || dc != 0) {
              // ignore: avoid_single_cascade_in_expression_statements
              stack.add([rr + dr, cc + dc]);
            }
          }
        }
      }
    }
  }

  void _checkWin() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cell = grid[r][c];
        if (!cell.mine && !cell.revealed) return;
      }
    }
    won = true;
  }
}
