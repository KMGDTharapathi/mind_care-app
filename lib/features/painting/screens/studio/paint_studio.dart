import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mind_care_app/features/painting/models/coloring_page.dart';

import 'canvas_painter.dart';
import 'paint_models.dart';
part 'paint_widgets.dart';

// ─── Isolate flood fill ───────────────────────────────────────────────────────

class _FillMsg {
  final Uint32List pixels;
  final int x, y, w, h;
  final int fill;
  const _FillMsg(this.pixels, this.x, this.y, this.w, this.h, this.fill);
}

void _fillIsolate(List<dynamic> args) {
  final SendPort port = args[0];
  final _FillMsg msg = args[1];
  final np = Uint32List.fromList(msg.pixels);
  final target = np[msg.y * msg.w + msg.x];
  if (target == msg.fill) { port.send(null); return; }
  final q = <int>[msg.y * msg.w + msg.x];
  while (q.isNotEmpty) {
    final i = q.removeLast();
    if (i < 0 || i >= np.length || np[i] != target) continue;
    final r = np[i] & 0xFF;
    final g = (np[i] >> 8) & 0xFF;
    final b = (np[i] >> 16) & 0xFF;
    if (r < 80 && g < 80 && b < 80) continue;
    np[i] = msg.fill;
    final px = i % msg.w, py = i ~/ msg.w;
    if (px > 0) q.add(i - 1);
    if (px < msg.w - 1) q.add(i + 1);
    if (py > 0) q.add(i - msg.w);
    if (py < msg.h - 1) q.add(i + msg.w);
  }
  port.send(np);
}

// ─── Studio ───────────────────────────────────────────────────────────────────

class PaintStudio extends StatefulWidget {
  const PaintStudio({super.key});
  @override
  State<PaintStudio> createState() => _PaintStudioState();
}

class _PaintStudioState extends State<PaintStudio> {
  // Canvas raster (800×800 logical pixels)
  ui.Image? _mandalaImage;
  Uint32List? _pixels;
  static const int _kW = 800, _kH = 800;

  // Strokes stored in canvas-space (0..800)
  final List<Stroke> _strokes = [];
  final List<List<Stroke>> _undoStack = [];
  Stroke? _current;

  // Shapes stored in render-space (widget pixels)
  final List<PlacedShape> _shapes = [];
  PlacedShape? _draggingShape;
  PlacedShape? _resizingShape;
  Offset? _dragOffset;
  ShapeKind? _pendingShape;

  // Tools
  BrushType _brush = BrushType.brush;
  ToolMode _tool = ToolMode.draw;
  Color _color = const Color(0xFF1E88E5);
  double _size = 8.0;
  double _opacity = 1.0;

  // Background
  Color _bgColor = Colors.white;
  List<Color>? _bgGradient;
  BgType _bgType = BgType.plain;

  // UI
  BottomTab _tab = BottomTab.mandalas;
  ColoringPage? _activeMandala;
  bool _loadingMandala = false;
  bool _filling = false;

  // Render size — set by LayoutBuilder, used to convert touch → canvas coords
  Size _renderSize = Size.zero;

  // ── Coordinate conversion ──────────────────────────────────────────────────

  /// Convert a touch position (render-space) to canvas-space (0..800)
  Offset _toCanvas(Offset renderPos) {
    if (_renderSize == Size.zero) return renderPos;
    return Offset(
      renderPos.dx * _kW / _renderSize.width,
      renderPos.dy * _kH / _renderSize.height,
    );
  }

  // ── Mandala loading ────────────────────────────────────────────────────────

  Future<void> _loadMandala(ColoringPage page) async {
    if (_activeMandala?.id == page.id) return;
    setState(() {
      _loadingMandala = true;
      _strokes.clear();
      _undoStack.clear();
    });
    final svgStr =
        await DefaultAssetBundle.of(context).loadString(page.assetPath);
    final info = await vg.loadPicture(SvgStringLoader(svgStr), null);
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    c.drawColor(Colors.white, BlendMode.src);
    c.scale(_kW / info.size.width, _kH / info.size.height);
    c.drawPicture(info.picture);
    info.picture.dispose();
    final pic = recorder.endRecording();
    final img = await pic.toImage(_kW, _kH);
    pic.dispose();
    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (!mounted || bd == null) return;
    setState(() {
      _mandalaImage = img;
      _pixels = bd.buffer.asUint32List();
      _activeMandala = page;
      _loadingMandala = false;
    });
  }

  // ── Flood fill (isolate) ───────────────────────────────────────────────────

  Future<void> _floodFill(Offset canvasPos) async {
    if (_pixels == null || _filling) return;
    final x = canvasPos.dx.round().clamp(0, _kW - 1);
    final y = canvasPos.dy.round().clamp(0, _kH - 1);
    final fill = _toRgba(_color);
    final target = _pixels![y * _kW + x];
    if (target == fill) return;
    // Don't fill dark stroke lines
    final r = target & 0xFF, g = (target >> 8) & 0xFF, b = (target >> 16) & 0xFF;
    if (r < 80 && g < 80 && b < 80) return;

    setState(() => _filling = true);

    final rp = ReceivePort();
    await Isolate.spawn(
      _fillIsolate,
      [rp.sendPort, _FillMsg(_pixels!, x, y, _kW, _kH, fill)],
    );
    final result = await rp.first as Uint32List?;
    rp.close();
    if (result == null || !mounted) {
      setState(() => _filling = false);
      return;
    }
    final comp = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        result.buffer.asUint8List(), _kW, _kH,
        ui.PixelFormat.rgba8888, comp.complete);
    final img = await comp.future;
    if (!mounted) return;
    setState(() {
      _mandalaImage = img;
      _pixels = result;
      _filling = false;
    });
  }

  int _toRgba(Color c) =>
      ((c.r * 255).round()) |
      (((c.g * 255).round()) << 8) |
      (((c.b * 255).round()) << 16) |
      (((c.a * 255).round()) << 24);

  // ── Draw gestures ──────────────────────────────────────────────────────────

  void _saveUndo() => _undoStack.add(List.from(_strokes));

  void _onPanStart(DragStartDetails d) {
    if (_tool == ToolMode.bucket) return;

    // Shape interaction
    if (_pendingShape == null) {
      for (int i = _shapes.length - 1; i >= 0; i--) {
        final sh = _shapes[i];
        final handle = Offset(
            sh.position.dx + sh.width / 2, sh.position.dy + sh.height / 2);
        if ((d.localPosition - handle).distance < 18) {
          setState(() {
            _shapes[i] = sh.copyWith(selected: true);
            _resizingShape = _shapes[i];
          });
          return;
        }
        final r = Rect.fromCenter(
            center: sh.position, width: sh.width, height: sh.height);
        if (r.contains(d.localPosition)) {
          setState(() {
            for (int j = 0; j < _shapes.length; j++) {
              _shapes[j] = _shapes[j].copyWith(selected: j == i);
            }
            _draggingShape = _shapes[i];
            _dragOffset = d.localPosition - sh.position;
          });
          return;
        }
      }
      // Deselect all
      for (int j = 0; j < _shapes.length; j++) {
        _shapes[j] = _shapes[j].copyWith(selected: false);
      }
      _draggingShape = null;
      _resizingShape = null;
    }

    _saveUndo();
    // Convert to canvas-space for stroke storage
    final cp = _toCanvas(d.localPosition);
    setState(() {
      _current = Stroke(
        points: [cp],
        color: _color,
        size: _size,
        opacity: _opacity,
        brush: _brush,
        isEraser: _tool == ToolMode.eraser,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_resizingShape != null) {
      final idx = _shapes.indexOf(_resizingShape!);
      if (idx >= 0) {
        final nw = ((d.localPosition.dx - _resizingShape!.position.dx) * 2)
            .abs()
            .clamp(20.0, 400.0);
        final nh = ((d.localPosition.dy - _resizingShape!.position.dy) * 2)
            .abs()
            .clamp(20.0, 400.0);
        setState(() {
          _shapes[idx] = _resizingShape!.copyWith(width: nw, height: nh);
          _resizingShape = _shapes[idx];
        });
      }
      return;
    }
    if (_draggingShape != null) {
      final idx = _shapes.indexOf(_draggingShape!);
      if (idx >= 0) {
        setState(() {
          _shapes[idx] =
              _draggingShape!.copyWith(position: d.localPosition - _dragOffset!);
          _draggingShape = _shapes[idx];
        });
      }
      return;
    }
    if (_current == null) return;
    final cp = _toCanvas(d.localPosition);
    setState(() => _current = _current!.addPoint(cp));
  }

  void _onPanEnd(DragEndDetails _) {
    _draggingShape = null;
    _resizingShape = null;
    _dragOffset = null;
    if (_current == null) return;
    setState(() {
      _strokes.add(_current!);
      _current = null;
    });
  }

  void _onTapUp(TapUpDetails d) {
    if (_tool == ToolMode.bucket) {
      _floodFill(_toCanvas(d.localPosition));
      return;
    }
    if (_pendingShape != null) {
      setState(() {
        _shapes.add(PlacedShape(
          kind: _pendingShape!,
          position: d.localPosition,
          color: _color,
          selected: true,
        ));
        _pendingShape = null;
      });
    }
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _strokes
        ..clear()
        ..addAll(_undoStack.removeLast());
    });
  }

  void _clear() {
    _saveUndo();
    setState(() {
      _strokes.clear();
      _shapes.clear();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onBack: () => Navigator.of(context).pop(),
              onUndo: _undoStack.isNotEmpty ? _undo : null,
              onClear: _clear,
            ),
            _BrushRow(
              brush: _brush,
              tool: _tool,
              onBrush: (b) => setState(() {
                _brush = b;
                _tool = ToolMode.draw;
              }),
              onBucket: () => setState(() => _tool = ToolMode.bucket),
              onEraser: () => setState(() => _tool = ToolMode.eraser),
            ),
            Expanded(child: _buildCanvas()),
            _PaletteRow(
              color: _color,
              tool: _tool,
              onColor: (c) => setState(() {
                _color = c;
                if (_tool == ToolMode.eraser) _tool = ToolMode.draw;
              }),
              onEraser: () => setState(() => _tool = ToolMode.eraser),
            ),
            _SizeOpacityRow(
              size: _size,
              opacity: _opacity,
              onSize: (v) => setState(() => _size = v),
              onOpacity: (v) => setState(() => _opacity = v),
            ),
            _BottomTabBar(
              tab: _tab,
              onTab: (t) =>
                  setState(() => _tab = _tab == t ? BottomTab.mandalas : t),
            ),
            _buildPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: _loadingMandala
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2979FF)))
              : LayoutBuilder(builder: (ctx, box) {
                  // Store render size for coordinate conversion
                  _renderSize = Size(box.maxWidth, box.maxHeight);
                  return Stack(
                    children: [
                      GestureDetector(
                        onTapUp: _onTapUp,
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          painter: CanvasPainter(
                            mandala: _mandalaImage,
                            strokes: _strokes,
                            current: _current,
                            shapes: _shapes,
                            bgColor: _bgColor,
                            bgGradient: _bgGradient,
                            bgType: _bgType,
                            renderSize: _renderSize,
                          ),
                          child: SizedBox(
                            width: box.maxWidth,
                            height: box.maxHeight,
                          ),
                        ),
                      ),
                      if (_filling)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.08),
                            child: const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF2979FF)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    switch (_tab) {
      case BottomTab.mandalas:
        return _MandalaPanel(
          mandalas: kMandalas,
          active: _activeMandala,
          onSelect: _loadMandala,
        );
      case BottomTab.emojis:
        return _EmojiPanel(
          onEmoji: (e) {
            setState(() => _pendingShape = ShapeKind.circle);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tap canvas to place $e'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      case BottomTab.background:
        return _BackgroundPanel(
          onSelect: (opt) => setState(() {
            if (opt.type == BgType.plain) {
              _bgColor = opt.color!;
              _bgGradient = null;
              _bgType = BgType.plain;
            } else if (opt.type == BgType.gradient) {
              _bgGradient = opt.gradientColors;
              _bgType = BgType.gradient;
            } else {
              _bgType = BgType.texture;
              _bgGradient = null;
            }
          }),
        );
      case BottomTab.shapes:
        return _ShapesPanel(
          pending: _pendingShape,
          onShape: (k) {
            setState(() {
              _pendingShape = k;
              _tool = ToolMode.draw;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tap canvas to place shape'),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      case BottomTab.export:
        return _ExportPanel(
          onExport: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Export coming soon'),
                behavior: SnackBarBehavior.floating),
          ),
        );
    }
  }
}
