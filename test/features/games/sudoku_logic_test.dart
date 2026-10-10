import 'package:flutter_test/flutter_test.dart';
import 'package:mind_care_app/features/games/logic/sudoku_logic.dart';

void main() {
  group('Sudoku', () {
    final sudoku = Sudoku(seed: 42);

    test('generates a puzzle with a valid, unique solution', () {
      final p = sudoku.generate(clues: 36);
      expect(sudoku.isSolved(p.solution), true);
      expect(sudoku.countSolutions(p.puzzle, limit: 2), 1);
      expect(p.clues, greaterThan(0));
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (p.puzzle[r][c] != 0) {
            expect(p.puzzle[r][c], p.solution[r][c]);
          }
        }
      }
    });

    test('solve() completes the puzzle to its unique solution', () {
      final p = sudoku.generate(clues: 40);
      expect(sudoku.solve(p.puzzle), p.solution);
    });

    test('isValidPlacement rejects row, column and box conflicts', () {
      final g = sudoku.emptyGrid();
      g[0][0] = 5;
      expect(sudoku.isValidPlacement(g, 0, 4, 5), false);
      expect(sudoku.isValidPlacement(g, 4, 0, 5), false);
      expect(sudoku.isValidPlacement(g, 1, 1, 5), false);
      expect(sudoku.isValidPlacement(g, 4, 4, 5), true);
    });

    test('isSolved is false for an empty grid and true for a solution', () {
      expect(sudoku.isSolved(sudoku.emptyGrid()), false);
      final p = sudoku.generate(clues: 40);
      expect(sudoku.isSolved(p.solution), true);
    });
  });
}
