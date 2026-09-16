import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/game_exit_dialog.dart';

void main() => runApp(const BubbleShooterApp());

class BubbleShooterApp extends StatelessWidget {
  const BubbleShooterApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true),
    home: const BubbleShooterGame(),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════════
const int kCols = 8;
const int kGridRows = 7;
const double kBubbleR = 22.0;

const List<Color> kColors = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFDD835),
  Color(0xFF8E24AA),
  Color(0xFFFF7043),
];

class _LevelDef {
  final int shots;
  final int numColors;
  const _LevelDef(this.shots, this.numColors);
}

const _levels = [
  _LevelDef(25, 2),
  _LevelDef(30, 3),
  _LevelDef(35, 3),
  _LevelDef(40, 4),
  _LevelDef(45, 4),
  _LevelDef(50, 5),
];

// ═══════════════════════════════════════════════════════════════════════════════
//  BUBBLE MODEL
// ═══════════════════════════════════════════════════════════════════════════════
class Bubble {
  int row, col, colorIdx;
  bool popping;
  Bubble(this.row, this.col, this.colorIdx) : popping = false;
}

typedef BubbleBlasterGame = BubbleShooterGame;

// ═══════════════════════════════════════════════════════════════════════════════
//  ISOLATE HELPERS
// ═══════════════════════════════════════════════════════════════════════════════
class _ShootInput {
  final double aimAngle, w, h;
  final List<Map<String, int>> gridData;
  final int curColor;
  _ShootInput({
    required this.aimAngle,
    required this.w,
    required this.h,
    required this.gridData,
    required this.curColor,
  });
}

class _ShootResult {
  final int landRow, landCol;
  final List<String> matched;
  _ShootResult(this.landRow, this.landCol, this.matched);
}

_ShootResult _computeShot(_ShootInput input) {
  final double w = input.w;
  final double h = input.h;
  final double angle = input.aimAngle;
  final int color = input.curColor;
  final grid = input.gridData;

  double cellW() => w / kCols;

  Offset cellCenter(int row, int col) {
    final cw = cellW();
    final cx = col * cw + cw / 2 + (row.isOdd ? cw / 2 : 0);
    final cy = row * (kBubbleR * 1.75) + kBubbleR + 4;
    return Offset(cx, cy);
  }

  List<(int, int)> hexNeighbors(int r, int c) {
    if (r.isEven) {
      return [
        (r - 1, c - 1),
        (r - 1, c),
        (r, c - 1),
        (r, c + 1),
        (r + 1, c - 1),
        (r + 1, c),
      ];
    } else {
      return [
        (r - 1, c),
        (r - 1, c + 1),
        (r, c - 1),
        (r, c + 1),
        (r + 1, c),
        (r + 1, c + 1),
      ];
    }
  }

  double vx = sin(angle);
  double vy = -cos(angle);
  double px = w / 2;
  double py = h - 72;

  int landRow = 0, landCol = 0;
  bool placed = false;

  for (int step = 0; step < 6000; step++) {
    px += vx * 2.0;
    py += vy * 2.0;

    if (px < kBubbleR) {
      px = 2 * kBubbleR - px;
      vx = -vx;
    }
    if (px > w - kBubbleR) {
      px = 2 * (w - kBubbleR) - px;
      vx = -vx;
    }

    if (py <= kBubbleR + 4) {
      landRow = 0;
      final cw = cellW();
      landCol = ((px - (landRow.isOdd ? cw / 2 : 0)) / cw).round().clamp(
        0,
        kCols - 1,
      );
      placed = true;
      break;
    }

    for (final b in grid) {
      final bc = cellCenter(b['row']!, b['col']!);
      final dx = px - bc.dx;
      final dy = py - bc.dy;
      if (dx * dx + dy * dy < (kBubbleR * 1.85) * (kBubbleR * 1.85)) {
        final candidates = hexNeighbors(b['row']!, b['col']!);
        double best = double.infinity;
        landRow = b['row']!;
        landCol = b['col']!;
        for (final nb in candidates) {
          final nr = nb.$1;
          final nc = nb.$2;
          if (nr < 0 || nr > kGridRows + 2 || nc < 0 || nc >= kCols) continue;
          if (grid.any((g) => g['row'] == nr && g['col'] == nc)) continue;
          final nc2 = cellCenter(nr, nc);
          final dx2 = px - nc2.dx;
          final dy2 = py - nc2.dy;
          final d = dx2 * dx2 + dy2 * dy2;
          if (d < best) {
            best = d;
            landRow = nr;
            landCol = nc;
          }
        }
        placed = true;
        break;
      }
    }
    if (placed) break;
  }

  if (!placed) {
    landRow = 0;
    final cw = cellW();
    landCol = ((px - (landRow.isOdd ? cw / 2 : 0)) / cw).round().clamp(
      0,
      kCols - 1,
    );
  }

  landRow = landRow.clamp(0, kGridRows + 2);
  landCol = landCol.clamp(0, kCols - 1);

  final tempGrid = List<Map<String, int>>.from(grid)
    ..removeWhere((b) => b['row'] == landRow && b['col'] == landCol)
    ..add({'row': landRow, 'col': landCol, 'colorIdx': color});

  // BFS match
  final visited = <String>{};
  final queue = ['$landRow,$landCol'];
  while (queue.isNotEmpty) {
    final key = queue.removeLast();
    if (visited.contains(key)) continue;
    final parts = key.split(',');
    final r = int.parse(parts[0]);
    final c = int.parse(parts[1]);
    final b = tempGrid.where((b) => b['row'] == r && b['col'] == c).firstOrNull;
    if (b == null || b['colorIdx'] != color) continue;
    visited.add(key);
    for (final n in hexNeighbors(r, c)) {
      queue.add('${n.$1},${n.$2}');
    }
  }

  return _ShootResult(landRow, landCol, visited.toList());
}

// ═══════════════════════════════════════════════════════════════════════════════
//  GAME WIDGET
// ═══════════════════════════════════════════════════════════════════════════════
class BubbleShooterGame extends StatefulWidget {
  const BubbleShooterGame({super.key});
  @override
  State<BubbleShooterGame> createState() => _BubbleShooterState();
}

class _BubbleShooterState extends State<BubbleShooterGame>
    with TickerProviderStateMixin {
  final _rng = Random();
  int _level = 0;
  int _shots = 0;
  int _score = 0;
  int _curColor = 0;
  int _nextColor = 0;
  int _totalBubbles = 0; // total bubbles at level start
  List<Bubble> _grid = [];
  double? _aimAngle;
  bool _firing = false;
  bool _won = false;
  bool _lost = false;

  late AnimationController _popCtrl;

  @override
  void initState() {
    super.initState();
    _popCtrl =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 280),
          )
          ..addListener(() => setState(() {}))
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) {
              _grid.removeWhere((b) => b.popping);
              _popCtrl.reset();
              // ── WIN CHECK: all bubbles cleared ──
              if (_grid.isEmpty) {
                setState(() => _won = true);
              }
              setState(() {});
            }
          });
    _startLevel(0);
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    super.dispose();
  }

  void _startLevel(int lvl) {
    _level = lvl.clamp(0, _levels.length - 1);
    final def = _levels[_level];
    _shots = def.shots;
    _won = false;
    _lost = false;
    _aimAngle = null;
    _firing = false;
    _curColor = _rng.nextInt(def.numColors);
    _nextColor = _rng.nextInt(def.numColors);
    _grid = [];

    // Build full dense grid so clearing ALL is the challenge
    for (int r = 0; r < kGridRows; r++) {
      for (int c = 0; c < kCols; c++) {
        // Odd rows have one less bubble due to hex offset
        if (r.isOdd && c == kCols - 1) continue;
        _grid.add(Bubble(r, c, _rng.nextInt(def.numColors)));
      }
    }

    _totalBubbles = _grid.length;
    setState(() {});
  }

  double _cellW(double w) => w / kCols;

  Offset _cellCenter(int row, int col, double w) {
    final cw = _cellW(w);
    final cx = col * cw + cw / 2 + (row.isOdd ? cw / 2 : 0);
    final cy = row * (kBubbleR * 1.75) + kBubbleR + 4;
    return Offset(cx, cy);
  }

  Offset _gunPos(double w, double h) => Offset(w / 2, h - 72);

  void _handleAim(Offset local, double w, double h) {
    if (_firing || _won || _lost) return;
    final gun = _gunPos(w, h);
    final dx = local.dx - gun.dx;
    final dy = local.dy - gun.dy;
    if (dy >= -10) return;
    setState(() => _aimAngle = atan2(dx, -dy).clamp(-1.35, 1.35));
  }

  void _handleShoot(Offset local, double w, double h) {
    if (_firing || _won || _lost) return;
    final gun = _gunPos(w, h);
    final dy = local.dy - gun.dy;
    if (dy >= -10) return;
    if (_aimAngle == null) {
      final dx = local.dx - gun.dx;
      _aimAngle = atan2(dx, -dy).clamp(-1.35, 1.35);
    }
    _shoot(w, h);
  }

  Future<void> _shoot(double w, double h) async {
    if (_aimAngle == null || _firing || _won || _lost) return;
    setState(() => _firing = true);

    final gridData = _grid
        .map((b) => {'row': b.row, 'col': b.col, 'colorIdx': b.colorIdx})
        .toList();

    final result = await compute(
      _computeShot,
      _ShootInput(
        aimAngle: _aimAngle!,
        w: w,
        h: h,
        gridData: gridData,
        curColor: _curColor,
      ),
    );

    if (!mounted) return;

    _grid.removeWhere(
      (b) => b.row == result.landRow && b.col == result.landCol,
    );
    _grid.add(Bubble(result.landRow, result.landCol, _curColor));

    bool didPop = false;
    if (result.matched.length >= 3) {
      for (final b in _grid) {
        if (result.matched.contains('${b.row},${b.col}')) {
          b.popping = true;
        }
      }
      _score += result.matched.length * (_level + 1) * 10;
      didPop = true;
      _popCtrl.forward(from: 0);
    }

    _shots--;
    _curColor = _nextColor;
    _nextColor = _rng.nextInt(_levels[_level].numColors);
    _aimAngle = null;

    // ── WIN: all bubbles gone (handled in popCtrl listener too)
    // ── LOSE: no shots left AND bubbles still remain
    final remainingAfterPop = _grid.where((b) => !b.popping).length;
    final allGone = didPop && remainingAfterPop == 0;
    final outOfShots = _shots <= 0 && !allGone;

    setState(() {
      if (allGone) _won = true;
      if (outOfShots && !_won) _lost = true;
      _firing = false;
    });
  }

  List<Offset> _trajectory(double w, double h) {
    if (_aimAngle == null) return [];
    double vx = sin(_aimAngle!);
    double vy = -cos(_aimAngle!);
    double px = _gunPos(w, h).dx;
    double py = _gunPos(w, h).dy;
    final dots = <Offset>[];
    for (int step = 0; step < 2000; step++) {
      px += vx * 6;
      py += vy * 6;
      if (px < kBubbleR) {
        px = 2 * kBubbleR - px;
        vx = -vx;
      }
      if (px > w - kBubbleR) {
        px = 2 * (w - kBubbleR) - px;
        vx = -vx;
      }
      if (py < 4) break;
      bool hit = false;
      for (final b in _grid) {
        final dist = (Offset(px, py) - _cellCenter(b.row, b.col, w)).distance;
        if (dist < kBubbleR * 1.7) {
          hit = true;
          break;
        }
      }
      if (hit) break;
      if (step % 5 == 0) dots.add(Offset(px, py));
    }
    return dots;
  }

  // remaining bubbles count (excluding ones mid-pop)
  int get _remaining => _grid.where((b) => !b.popping).length;

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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D0D2B), Color(0xFF1A1A4E), Color(0xFF0D1B4B)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _won || _lost ? _buildResult() : _buildGame()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _statChip(
            Icons.emoji_events_rounded,
            'Score',
            '$_score',
            const Color(0xFFFFD600),
          ),
          const SizedBox(width: 8),
          _statChip(
            Icons.bubble_chart_rounded,
            'Left',
            '$_remaining / $_totalBubbles',
            const Color(0xFF69F0AE),
          ),
          const SizedBox(width: 8),
          _statChip(
            Icons.sports_esports_rounded,
            'Shots',
            '$_shots',
            const Color(0xFFFF6E40),
          ),
          const Spacer(),
          Column(
            children: [
              const Text(
                'NEXT',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white54,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kColors[_nextColor],
                  boxShadow: [
                    BoxShadow(
                      color: kColors[_nextColor].withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, String val, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.25), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: accent),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: accent.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Text(
              val,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGame() {
    return LayoutBuilder(
      builder: (ctx, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        return GestureDetector(
          onPanUpdate: (d) => _handleAim(d.localPosition, w, h),
          onPanEnd: (_) {
            if (_aimAngle != null && !_firing) _shoot(w, h);
          },
          onTapDown: (d) => _handleAim(d.localPosition, w, h),
          onTapUp: (d) => _handleShoot(d.localPosition, w, h),
          child: Stack(
            children: [
              CustomPaint(
                size: Size(w, h),
                painter: _GridPainter(
                  grid: _grid,
                  w: w,
                  h: h,
                  popProgress: _popCtrl.value,
                  curColor: _curColor,
                  aimAngle: _aimAngle,
                  trajectoryDots: _trajectory(w, h),
                  cellCenter: _cellCenter,
                  gunPos: _gunPos(w, h),
                  firing: _firing,
                ),
              ),
              // Level badge
              Positioned(
                top: 6,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'LV ${_level + 1}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              // Goal reminder banner
              Positioned(
                top: 36,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Clear ALL $_totalBubbles bubbles to win!',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              if (_firing)
                const Positioned(
                  bottom: 90,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Shooting...',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ),
              if (!_firing && _aimAngle == null)
                Positioned(
                  bottom: 90,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Drag or tap above to aim & shoot',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResult() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _won
                ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                : [const Color(0xFF7F0000), const Color(0xFFB71C1C)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: (_won ? Colors.green : Colors.red).withValues(alpha: 0.4),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_won ? '🎉' : '💔', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Text(
              _won ? 'All Bubbles Cleared!' : 'Out of Shots!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _won
                  ? 'Level ${_level + 1} Complete!\nScore: $_score'
                  : '$_remaining bubbles remaining\nScore: $_score',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            if (_won && _level < _levels.length - 1)
              _btn(
                'Next Level →',
                const Color(0xFF69F0AE),
                Colors.black,
                () => setState(() => _startLevel(_level + 1)),
              ),
            const SizedBox(height: 10),
            _btn(
              _won ? 'Replay Level' : 'Try Again',
              Colors.white.withValues(alpha: 0.15),
              Colors.white,
              () => setState(() => _startLevel(_level)),
            ),
            const SizedBox(height: 10),
            if (_level > 0)
              _btn(
                'Back to Lv 1',
                Colors.white.withValues(alpha: 0.08),
                Colors.white54,
                () => setState(() => _startLevel(0)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CUSTOM PAINTER
// ═══════════════════════════════════════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  final List<Bubble> grid;
  final double w, h, popProgress;
  final int curColor;
  final double? aimAngle;
  final List<Offset> trajectoryDots;
  final Offset Function(int, int, double) cellCenter;
  final Offset gunPos;
  final bool firing;

  _GridPainter({
    required this.grid,
    required this.w,
    required this.h,
    required this.popProgress,
    required this.curColor,
    required this.aimAngle,
    required this.trajectoryDots,
    required this.cellCenter,
    required this.gunPos,
    required this.firing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in grid) {
      final c = cellCenter(b.row, b.col, w);
      if (b.popping) {
        _drawBubble(
          canvas,
          c,
          kColors[b.colorIdx],
          radius: kBubbleR * (1.0 + popProgress * 0.6),
          opacity: 1 - popProgress,
        );
      } else {
        _drawBubble(canvas, c, kColors[b.colorIdx]);
      }
    }

    // Trajectory dots
    if (aimAngle != null && !firing) {
      for (int i = 0; i < trajectoryDots.length; i++) {
        final opacity = (1 - i / trajectoryDots.length) * 0.7;
        final r = i % 3 == 0 ? 4.0 : 2.5;
        canvas.drawCircle(
          trajectoryDots[i],
          r,
          Paint()..color = Colors.white.withValues(alpha: opacity),
        );
      }
    }

    // Gun base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(gunPos.dx, gunPos.dy + 26),
          width: 56,
          height: 22,
        ),
        const Radius.circular(11),
      ),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
            ).createShader(
              Rect.fromCenter(
                center: Offset(gunPos.dx, gunPos.dy + 26),
                width: 56,
                height: 22,
              ),
            ),
    );

    // Glow
    canvas.drawCircle(
      gunPos,
      kBubbleR + 8,
      Paint()
        ..color = kColors[curColor].withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Current bubble on gun
    _drawBubble(canvas, gunPos, kColors[curColor], radius: kBubbleR + 3);
  }

  void _drawBubble(
    Canvas canvas,
    Offset center,
    Color color, {
    double radius = kBubbleR,
    double opacity = 1.0,
  }) {
    canvas.drawCircle(
      center + const Offset(1, 2),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.3 * opacity),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 0.9,
          colors: [
            Color.lerp(color, Colors.white, 0.35)!.withValues(alpha: opacity),
            color.withValues(alpha: opacity),
            Color.lerp(color, Colors.black, 0.25)!.withValues(alpha: opacity),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    canvas.drawCircle(
      center - Offset(radius * 0.3, radius * 0.32),
      radius * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.55 * opacity),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_GridPainter old) => true;
}
