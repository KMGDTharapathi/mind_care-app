import 'package:flutter/material.dart';

enum BrushType { brush, pencil, marker, watercolor }
enum ToolMode { draw, bucket, eraser }
enum BottomTab { mandalas, emojis, background, shapes, export }

// ─── Stroke ───────────────────────────────────────────────────────────────────

class Stroke {
  final List<Offset> points;
  final Color color;
  final double size;
  final double opacity;
  final BrushType brush;
  final bool isEraser;

  const Stroke({
    required this.points,
    required this.color,
    required this.size,
    required this.opacity,
    required this.brush,
    this.isEraser = false,
  });

  Stroke addPoint(Offset p) => Stroke(
        points: [...points, p],
        color: color,
        size: size,
        opacity: opacity,
        brush: brush,
        isEraser: isEraser,
      );
}

// ─── Placed shape ─────────────────────────────────────────────────────────────

enum ShapeKind { circle, rect, triangle, star, heart, hexagon, arrow, diamond }

class PlacedShape {
  final ShapeKind kind;
  Offset position;
  double width;
  double height;
  Color color;
  bool selected;

  PlacedShape({
    required this.kind,
    required this.position,
    this.width = 80,
    this.height = 80,
    required this.color,
    this.selected = false,
  });

  PlacedShape copyWith({
    Offset? position,
    double? width,
    double? height,
    Color? color,
    bool? selected,
  }) =>
      PlacedShape(
        kind: kind,
        position: position ?? this.position,
        width: width ?? this.width,
        height: height ?? this.height,
        color: color ?? this.color,
        selected: selected ?? this.selected,
      );
}

// ─── Background ───────────────────────────────────────────────────────────────

enum BgType { plain, gradient, texture }

class BgOption {
  final BgType type;
  final Color? color;
  final List<Color>? gradientColors;
  final String? label;

  const BgOption.plain(this.color, this.label)
      : type = BgType.plain,
        gradientColors = null;

  const BgOption.gradient(this.gradientColors, this.label)
      : type = BgType.gradient,
        color = null;

  const BgOption.texture(this.label)
      : type = BgType.texture,
        color = null,
        gradientColors = null;
}

const kBgOptions = <BgOption>[
  BgOption.plain(Colors.white, 'White'),
  BgOption.plain(Color(0xFFFFF9C4), 'Cream'),
  BgOption.plain(Color(0xFFE8F5E9), 'Mint'),
  BgOption.plain(Color(0xFFE3F2FD), 'Sky'),
  BgOption.plain(Color(0xFFFCE4EC), 'Rose'),
  BgOption.plain(Color(0xFFF3E5F5), 'Lavender'),
  BgOption.plain(Color(0xFFE0F7FA), 'Aqua'),
  BgOption.plain(Color(0xFFFFF3E0), 'Peach'),
  BgOption.plain(Color(0xFF1A1A2E), 'Dark'),
  BgOption.plain(Color(0xFF0D1B2A), 'Night'),
  BgOption.gradient([Color(0xFFFF6B6B), Color(0xFFFFD93D)], 'Sunset'),
  BgOption.gradient([Color(0xFF4D96FF), Color(0xFF7C4DFF)], 'Ocean'),
  BgOption.gradient([Color(0xFF6BCB77), Color(0xFF4D96FF)], 'Forest'),
  BgOption.gradient([Color(0xFFFF4D9E), Color(0xFF7C4DFF)], 'Berry'),
  BgOption.gradient([Color(0xFFFFD93D), Color(0xFF6BCB77)], 'Spring'),
  BgOption.gradient([Color(0xFF00D4AA), Color(0xFF4D96FF)], 'Teal'),
  BgOption.texture('Dots'),
  BgOption.texture('Grid'),
  BgOption.texture('Lines'),
];

// ─── Palette ──────────────────────────────────────────────────────────────────

const kPalette = <Color>[
  Color(0xFFE53935), Color(0xFFE64A19), Color(0xFFFB8C00),
  Color(0xFFFFB300), Color(0xFFAFB42B), Color(0xFF43A047),
  Color(0xFF00897B), Color(0xFF039BE5), Color(0xFF1E88E5),
  Color(0xFF3949AB), Color(0xFF8E24AA), Color(0xFFD81B60),
  Color(0xFFEF9A9A), Color(0xFFFFCC80), Color(0xFFFFF176),
  Color(0xFFA5D6A7), Color(0xFF80DEEA), Color(0xFF90CAF9),
  Color(0xFFCE93D8), Color(0xFFF48FB1), Color(0xFFBCAAA4),
  Color(0xFF90A4AE), Color(0xFFFFFFFF), Color(0xFF212121),
];

const kEmojis = [
  '😀','😂','😍','🥰','😎','🤩','😇','🥳',
  '😢','😡','😱','🤔','😴','🤗','😏','🙄',
  '❤️','🧡','💛','💚','💙','💜','🖤','🤍',
  '⭐','🌟','✨','💫','🔥','🌈','🌸','🌺',
  '🦋','🐝','🌻','🍀','🌙','☀️','⛅','🌊',
  '🎵','🎶','🎨','🎭','🎪','🎠','🎡','🎢',
  '🍎','🍓','🍇','🍊','🍋','🍉','🍒','🍑',
  '🦁','🐯','🐻','🦊','🐺','🦝','🐼','🐨',
];
