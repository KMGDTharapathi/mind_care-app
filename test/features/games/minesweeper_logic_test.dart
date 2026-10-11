import 'package:flutter_test/flutter_test.dart';
import 'package:mind_care_app/features/games/logic/minesweeper_logic.dart';

void main() {
  group('Minesweeper', () {
    test('the first reveal is always safe', () {
      final g = Minesweeper(rows: 9, cols: 9, totalMines: 10, seed: 3);
      g.reveal(4, 4);
      expect(g.exploded, false);
      expect(g.grid[4][4].revealed, true);
      for (var r = 3; r <= 5; r++) {
        for (var c = 3; c <= 5; c++) {
          expect(g.grid[r][c].mine, false);
        }
      }
    });

    test('flagging updates the mine counter', () {
      final g = Minesweeper(rows: 9, cols: 9, totalMines: 10, seed: 3);
      g.toggleFlag(0, 0);
      expect(g.grid[0][0].flagged, true);
      expect(g.flagsUsed, 1);
      expect(g.minesLeft, 9);
      g.toggleFlag(0, 0);
      expect(g.flagsUsed, 0);
    });

    test('a safe zero-cell reveal clears the board and wins', () {
      final g = Minesweeper(rows: 3, cols: 3, totalMines: 1, seed: 5);
      g.reveal(1, 1);
      expect(g.won, true);
      for (final row in g.grid) {
        for (final cell in row) {
          expect(cell.revealed, true);
        }
      }
    });

    test('revealing a mine ends the game', () {
      final g = Minesweeper(rows: 3, cols: 3, totalMines: 1, seed: 5);
      g.generated = true;
      g.grid[0][0].mine = true;
      g.reveal(0, 0);
      expect(g.exploded, true);
      expect(g.isOver, true);
    });
  });
}
