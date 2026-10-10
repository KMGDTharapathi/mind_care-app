import 'package:flutter_test/flutter_test.dart';
import 'package:mind_care_app/features/games/logic/game_2048_logic.dart';

void main() {
  group('Game2048', () {
    test('starts with two tiles and zero score', () {
      final g = Game2048(seed: 1);
      expect(g.score, 0);
      final filled = g.board.expand((r) => r).where((v) => v != 0).length;
      expect(filled, 2);
    });

    test('merges equal tiles and adds score', () {
      final g = Game2048(seed: 1);
      g.board = [
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ];
      final changed = g.move(SwipeDir.left);
      expect(changed, true);
      expect(g.board[0][0], 4);
      expect(g.score, 4);
    });

    test('returns false when nothing moves', () {
      final g = Game2048(seed: 1);
      g.board = [
        [2, 4, 8, 16],
        [4, 8, 16, 32],
        [8, 16, 32, 64],
        [16, 32, 64, 128],
      ];
      expect(g.move(SwipeDir.left), false);
    });

    test('undo restores the previous board and score', () {
      final g = Game2048(seed: 1);
      g.board = [
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ];
      g.move(SwipeDir.left);
      expect(g.canUndo, true);
      g.undo();
      expect(g.board[0][0], 2);
      expect(g.board[0][1], 2);
      expect(g.score, 0);
    });

    test('reaching 2048 sets the win flag', () {
      final g = Game2048(seed: 1);
      g.board = [
        [1024, 1024, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ];
      g.move(SwipeDir.left);
      expect(g.won, true);
      expect(g.maxTile, 2048);
    });
  });
}
