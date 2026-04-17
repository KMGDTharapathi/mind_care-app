class ColoringPage {
  final String id;
  final String title;
  final String assetPath;

  const ColoringPage({
    required this.id,
    required this.title,
    required this.assetPath,
  });
}

const List<ColoringPage> kMandalas = [
  ColoringPage(id: 'm1', title: 'Petal Ring',   assetPath: 'assets/coloring/mandala1.svg'),
  ColoringPage(id: 'm2', title: 'Star Bloom',   assetPath: 'assets/coloring/mandala2.svg'),
  ColoringPage(id: 'm3', title: 'Lotus',        assetPath: 'assets/coloring/mandala3.svg'),
  ColoringPage(id: 'm4', title: 'Diamond',      assetPath: 'assets/coloring/mandala4.svg'),
  ColoringPage(id: 'm5', title: 'Teardrop',     assetPath: 'assets/coloring/mandala5.svg'),
  ColoringPage(id: 'm6', title: 'Arch Crown',   assetPath: 'assets/coloring/mandala6.svg'),
];
