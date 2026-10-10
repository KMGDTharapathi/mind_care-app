import 'dart:math';

/// A generated Sudoku: [puzzle] has `0` for the blank cells, [solution] is the
/// fully filled grid.
class SudokuPuzzle {
  final List<List<int>> puzzle;
  final List<List<int>> solution;
  const SudokuPuzzle(this.puzzle, this.solution);

  int get clues {
    var n = 0;
    for (final row in puzzle) {
      for (final v in row) {
        if (v != 0) n++;
      }
    }
    return n;
  }
}

/// Pure, testable Sudoku generator/solver — no Flutter dependency.
class Sudoku {
  final Random _rng;
  Sudoku({int? seed}) : _rng = Random(seed);

  List<List<int>> emptyGrid() => List.generate(9, (_) => List.filled(9, 0));

  /// Generates a puzzle with roughly [clues] givens and a unique solution.
  SudokuPuzzle generate({int clues = 36}) {
    final solution = List.generate(9, (_) => List.filled(9, 0));
    _fill(solution);

    final puzzle = [for (final row in solution) List.of(row)];
    final positions = <List<int>>[];
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        positions.add([r, c]);
      }
    }
    positions.shuffle(_rng);

    var filled = 81;
    for (final p in positions) {
      if (filled <= clues) break;
      final r = p[0];
      final c = p[1];
      final backup = puzzle[r][c];
      if (backup == 0) continue;
      puzzle[r][c] = 0;
      if (countSolutions(puzzle, limit: 2) != 1) {
        puzzle[r][c] = backup; // removing this clue would break uniqueness
      } else {
        filled--;
      }
    }
    return SudokuPuzzle(puzzle, solution);
  }

  /// Solves a copy of [grid] and returns it (blanks become filled).
  List<List<int>> solve(List<List<int>> grid) {
    final g = [for (final row in grid) List.of(row)];
    _fill(g);
    return g;
  }

  /// Counts solutions of [grid], stopping once [limit] is reached.
  int countSolutions(List<List<int>> grid, {int limit = 2}) {
    final g = [for (final row in grid) List.of(row)];
    return _count(g, limit);
  }

  /// Whether placing [value] at (r, c) breaks any Sudoku rule.
  bool isValidPlacement(List<List<int>> grid, int r, int c, int value) {
    if (value < 1 || value > 9) return false;
    for (var i = 0; i < 9; i++) {
      if (i != c && grid[r][i] == value) return false;
      if (i != r && grid[i][c] == value) return false;
    }
    final br = r - r % 3;
    final bc = c - c % 3;
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        final rr = br + i;
        final cc = bc + j;
        if ((rr != r || cc != c) && grid[rr][cc] == value) return false;
      }
    }
    return true;
  }

  /// True when the grid is fully filled and rule-abiding.
  bool isSolved(List<List<int>> grid) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final v = grid[r][c];
        if (v < 1 || v > 9) return false;
        if (!isValidPlacement(grid, r, c, v)) return false;
      }
    }
    return true;
  }

  // ── internals ──────────────────────────────────────────────────────────────

  bool _safe(List<List<int>> g, int r, int c, int v) {
    for (var i = 0; i < 9; i++) {
      if (g[r][i] == v || g[i][c] == v) return false;
    }
    final br = r - r % 3;
    final bc = c - c % 3;
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        if (g[br + i][bc + j] == v) return false;
      }
    }
    return true;
  }

  /// Fills [g] completely with a random valid solution (backtracking, MRV).
  bool _fill(List<List<int>> g) {
    final cell = _mostConstrained(g);
    if (cell == null) return true;
    final r = cell[0];
    final c = cell[1];
    final vals = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(_rng);
    for (final v in vals) {
      if (_safe(g, r, c, v)) {
        g[r][c] = v;
        if (_fill(g)) return true;
        g[r][c] = 0;
      }
    }
    return false;
  }

  int _count(List<List<int>> g, int limit) {
    final cell = _firstEmpty(g);
    if (cell == null) return 1;
    var total = 0;
    for (var v = 1; v <= 9; v++) {
      if (_safe(g, cell[0], cell[1], v)) {
        g[cell[0]][cell[1]] = v;
        total += _count(g, limit);
        g[cell[0]][cell[1]] = 0;
        if (total >= limit) return total;
      }
    }
    return total;
  }

  List<int>? _firstEmpty(List<List<int>> g) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (g[r][c] == 0) return [r, c];
      }
    }
    return null;
  }

  /// Minimum-remaining-values cell — keeps generation fast.
  List<int>? _mostConstrained(List<List<int>> g) {
    var bestR = -1;
    var bestC = -1;
    var bestCount = 10;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (g[r][c] != 0) continue;
        var count = 0;
        for (var v = 1; v <= 9; v++) {
          if (_safe(g, r, c, v)) count++;
        }
        if (count < bestCount) {
          bestCount = count;
          bestR = r;
          bestC = c;
          if (count == 0) return [r, c];
        }
      }
    }
    if (bestR == -1) return null;
    return [bestR, bestC];
  }
}
