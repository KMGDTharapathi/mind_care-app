part of 'paint_studio.dart';

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onUndo;
  final VoidCallback onClear;
  const _TopBar({required this.onBack, this.onUndo, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Row(children: [
              Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1A1A2E)),
              SizedBox(width: 4),
              Text('Canvas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            ]),
          ),
          const Spacer(),
          _TBtn(icon: Icons.undo_rounded, enabled: onUndo != null, onTap: onUndo ?? () {}),
          _TBtn(icon: Icons.redo_rounded, enabled: false, onTap: () {}),
          _TBtn(icon: Icons.delete_outline_rounded, enabled: true, onTap: onClear),
          _TBtn(icon: Icons.download_rounded, enabled: true, onTap: () {}),
        ],
      ),
    );
  }
}

class _TBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _TBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: enabled ? Colors.grey.shade100 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, size: 17, color: enabled ? Colors.black87 : Colors.grey.shade400),
      ),
    );
  }
}

// ─── Brush row ────────────────────────────────────────────────────────────────

class _BrushRow extends StatelessWidget {
  final BrushType brush;
  final ToolMode tool;
  final void Function(BrushType) onBrush;
  final VoidCallback onBucket;
  final VoidCallback onEraser;

  const _BrushRow({
    required this.brush,
    required this.tool,
    required this.onBrush,
    required this.onBucket,
    required this.onEraser,
  });

  @override
  Widget build(BuildContext context) {
    const brushes = [
      (BrushType.brush, '🖌️', 'Brush'),
      (BrushType.pencil, '✏️', 'Pencil'),
      (BrushType.marker, '🖊️', 'Marker'),
      (BrushType.watercolor, '💧', 'Watercolor'),
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          ...brushes.map((b) {
            final sel = brush == b.$1 && tool == ToolMode.draw;
            return _BrushChip(
              emoji: b.$2,
              label: b.$3,
              selected: sel,
              onTap: () => onBrush(b.$1),
            );
          }),
          _BrushChip(
            emoji: '🪣',
            label: 'Fill',
            selected: tool == ToolMode.bucket,
            onTap: onBucket,
            color: const Color(0xFF00897B),
          ),
          _BrushChip(
            emoji: '🧹',
            label: 'Eraser',
            selected: tool == ToolMode.eraser,
            onTap: onEraser,
            color: const Color(0xFFE53935),
          ),
        ],
      ),
    );
  }
}

class _BrushChip extends StatelessWidget {
  final String emoji, label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _BrushChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = const Color(0xFF2979FF),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Palette row ──────────────────────────────────────────────────────────────

class _PaletteRow extends StatelessWidget {
  final Color color;
  final ToolMode tool;
  final void Function(Color) onColor;
  final VoidCallback onEraser;

  const _PaletteRow({
    required this.color,
    required this.tool,
    required this.onColor,
    required this.onEraser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          GestureDetector(
            onTap: onEraser,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: tool == ToolMode.eraser
                      ? const Color(0xFF2979FF)
                      : Colors.grey.shade300,
                  width: tool == ToolMode.eraser ? 2.5 : 1.5,
                ),
              ),
              child: const Icon(Icons.auto_fix_normal_rounded, size: 15, color: Colors.black54),
            ),
          ),
          ...kPalette.map((c) {
            final sel = c == color && tool != ToolMode.eraser;
            return GestureDetector(
              onTap: () => onColor(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: sel ? 34 : 30,
                height: sel ? 34 : 30,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: sel ? const Color(0xFF2979FF) : Colors.grey.shade300,
                    width: sel ? 2.5 : 1,
                  ),
                  boxShadow: sel
                      ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)]
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Size / Opacity ───────────────────────────────────────────────────────────

class _SizeOpacityRow extends StatelessWidget {
  final double size, opacity;
  final void Function(double) onSize, onOpacity;

  const _SizeOpacityRow({
    required this.size,
    required this.opacity,
    required this.onSize,
    required this.onOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Row(
        children: [
          const Text('Size', style: TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(width: 4),
          Expanded(child: _Slider(value: size, min: 1, max: 60, onChanged: onSize)),
          Text('${size.round()}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(width: 12),
          const Text('Opacity', style: TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(width: 4),
          Expanded(child: _Slider(value: opacity, min: 0.05, max: 1.0, onChanged: onOpacity)),
          Text('${(opacity * 100).round()}%', style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  final double value, min, max;
  final void Function(double) onChanged;
  const _Slider({required this.value, required this.min, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: const Color(0xFF2979FF),
        inactiveTrackColor: Colors.grey.shade200,
        thumbColor: const Color(0xFF2979FF),
        overlayColor: const Color(0xFF2979FF).withValues(alpha: 0.15),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      child: Slider(value: value, min: min, max: max, onChanged: onChanged),
    );
  }
}

// ─── Bottom tab bar ───────────────────────────────────────────────────────────

class _BottomTabBar extends StatelessWidget {
  final BottomTab tab;
  final void Function(BottomTab) onTab;

  const _BottomTabBar({required this.tab, required this.onTab});

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (BottomTab.mandalas, '🌸', 'Mandalas', Color(0xFFE91E63)),
      (BottomTab.emojis, '😊', 'Emojis', Color(0xFFFFC107)),
      (BottomTab.background, '🎨', 'Background', Color(0xFF4CAF50)),
      (BottomTab.shapes, '⬜', 'Shapes', Color(0xFF9C27B0)),
      (BottomTab.export, '💾', 'Export', Color(0xFF2196F3)),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map((t) {
          final sel = tab == t.$1;
          return GestureDetector(
            onTap: () => onTab(t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? t.$4.withValues(alpha: 0.12) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? t.$4 : Colors.grey.shade200,
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.$2, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(t.$3,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: sel ? t.$4 : Colors.black54)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Mandala panel ────────────────────────────────────────────────────────────

class _MandalaPanel extends StatelessWidget {
  final List<ColoringPage> mandalas;
  final ColoringPage? active;
  final void Function(ColoringPage) onSelect;

  const _MandalaPanel({required this.mandalas, required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
        itemCount: mandalas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final m = mandalas[i];
          final sel = active?.id == m.id;
          return GestureDetector(
            onTap: () => onSelect(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? const Color(0xFF2979FF) : Colors.grey.shade200,
                  width: sel ? 2.5 : 1,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: SvgPicture.asset(m.assetPath, fit: BoxFit.contain),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(m.title,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: sel ? const Color(0xFF2979FF) : Colors.black54)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Emoji panel ──────────────────────────────────────────────────────────────

class _EmojiPanel extends StatelessWidget {
  final void Function(String) onEmoji;
  const _EmojiPanel({required this.onEmoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1,
        ),
        itemCount: kEmojis.length,
        itemBuilder: (ctx, i) => GestureDetector(
          onTap: () => onEmoji(kEmojis[i]),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(kEmojis[i], style: const TextStyle(fontSize: 22)),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Background panel ─────────────────────────────────────────────────────────

class _BackgroundPanel extends StatelessWidget {
  final void Function(BgOption) onSelect;
  const _BackgroundPanel({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kBgOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final opt = kBgOptions[i];
          return GestureDetector(
            onTap: () => onSelect(opt),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                    color: opt.type == BgType.plain ? opt.color : null,
                    gradient: opt.type == BgType.gradient
                        ? LinearGradient(
                            colors: opt.gradientColors!,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: opt.type == BgType.texture
                      ? CustomPaint(painter: _TexturePreviewPainter())
                      : null,
                ),
                const SizedBox(height: 4),
                Text(opt.label ?? '',
                    style: const TextStyle(fontSize: 9, color: Colors.black54)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TexturePreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final p = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Shapes panel ─────────────────────────────────────────────────────────────

class _ShapesPanel extends StatelessWidget {
  final ShapeKind? pending;
  final void Function(ShapeKind) onShape;

  const _ShapesPanel({required this.pending, required this.onShape});

  @override
  Widget build(BuildContext context) {
    const shapes = [
      (ShapeKind.circle, '⭕', 'Circle'),
      (ShapeKind.rect, '⬜', 'Rectangle'),
      (ShapeKind.triangle, '🔺', 'Triangle'),
      (ShapeKind.star, '⭐', 'Star'),
      (ShapeKind.heart, '❤️', 'Heart'),
      (ShapeKind.hexagon, '⬡', 'Hexagon'),
      (ShapeKind.arrow, '⬆️', 'Arrow'),
      (ShapeKind.diamond, '💎', 'Diamond'),
    ];
    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shapes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final s = shapes[i];
          final sel = pending == s.$1;
          return GestureDetector(
            onTap: () => onShape(s.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 70,
              decoration: BoxDecoration(
                color: sel
                    ? const Color(0xFF9C27B0).withValues(alpha: 0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? const Color(0xFF9C27B0) : Colors.grey.shade200,
                  width: sel ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.$2, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(s.$3,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: sel ? const Color(0xFF9C27B0) : Colors.black54)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Export panel ─────────────────────────────────────────────────────────────

class _ExportPanel extends StatelessWidget {
  final VoidCallback onExport;
  const _ExportPanel({required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Save to Gallery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
