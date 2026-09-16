import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:mind_care_app/core/l10n/app_strings.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';
import 'package:mind_care_app/features/motivational/data/quotes_data.dart';

// App main teal color
const _kTeal = Color(0xFF5BA8A0);

class MotivationalScreen extends StatefulWidget {
  const MotivationalScreen({super.key});
  @override
  State<MotivationalScreen> createState() => _MotivationalScreenState();
}

class _MotivationalScreenState extends State<MotivationalScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Lazily-created stable GlobalKeys — one per quote id, created on first access.
  // This avoids creating 150 keys synchronously in a single build frame.
  final Map<String, GlobalKey> _cardKeys = {};
  GlobalKey _keyFor(String id) => _cardKeys.putIfAbsent(id, GlobalKey.new);

  // _CategoryItem separates the localized display label from the canonical English filter value
  static const _categoryValues = [
    'All',
    'love',
    'strength',
    'success',
    'mindfulness',
    'courage',
    'happiness',
    'growth',
    'caring',
    'resilience',
    'peace',
  ];

  List<String> _categoryLabels(AppStrings s) => [
    s.categoryAll,
    s.categoryLove,
    s.categoryStrength,
    s.categorySuccess,
    s.categoryMindfulness,
    s.categoryCourage,
    s.categoryHappiness,
    s.categoryGrowth,
    s.categoryCaring,
    s.categoryResilience,
    s.categoryPeace,
  ];

  List<Quote> _filteredQuotes(bool isSinhala) {
    return kQuotes.where((q) {
      final matchesCategory =
          _selectedCategory == 'All' ||
          q.category.toLowerCase() == _selectedCategory.toLowerCase();
      if (_searchQuery.isEmpty) return matchesCategory;
      final query = _searchQuery.toLowerCase();
      final matchesSearch = isSinhala
          ? ((q.textSi ?? q.text).toLowerCase().contains(query) ||
                (q.authorSi ?? q.author).toLowerCase().contains(query) ||
                q.category.toLowerCase().contains(query))
          : (q.text.toLowerCase().contains(query) ||
                q.author.toLowerCase().contains(query) ||
                q.category.toLowerCase().contains(query));
      return matchesCategory && matchesSearch;
    }).toList();
  }

  double _cardHeight(Quote q, bool isSinhala) {
    final txt = isSinhala ? (q.textSi ?? q.text) : q.text;
    if (q.imageUrl != null) return 200 + (txt.length > 80 ? 40.0 : 0);
    if (txt.length > 120) return 200;
    if (txt.length > 80) return 175;
    if (txt.length > 50) return 155;
    return 135;
  }

  Future<void> _downloadCard(
    GlobalKey key,
    Quote quote,
    AppStrings strings,
  ) async {
    try {
      await Future.delayed(Duration.zero);
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List bytes = byteData.buffer.asUint8List();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${strings.saveQuote}! (${bytes.length ~/ 1024}KB)'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _kTeal,
        ),
      );
    } catch (e) {
      debugPrint('Download error: $e');
    }
  }

  void _showQuoteDetail(Quote quote, GlobalKey key, AppStrings strings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuoteDetailSheet(
        quote: quote,
        onDownload: () => _downloadCard(key, quote, strings),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LanguageProvider.of(context);
    final isSinhala = strings.isSinhala;
    final filtered = _filteredQuotes(isSinhala);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1A1A) : const Color(0xFFF0F9F9);

    return Scaffold(
      backgroundColor: bg,
      body: LeafBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(filtered.length, isDark, strings),
              _buildSearchBar(isDark, strings),
              _buildCategoryChips(isDark, strings),
              Expanded(child: _buildMasonryGrid(filtered, isSinhala, strings)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int count, bool isDark, AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : const Color(0xFF1A4A4A),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Text(
            strings.motivationalBoostTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A4A4A),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kTeal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: strings.searchQuotesHint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: _kTeal),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: _kTeal, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(bool isDark, AppStrings strings) {
    final labels = _categoryLabels(strings);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categoryValues.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final value = _categoryValues[i];
          final label = labels[i];
          final selected = _selectedCategory == value;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? _kTeal
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.grey.shade700),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMasonryGrid(
    List<Quote> quotes,
    bool isSinhala,
    AppStrings strings,
  ) {
    if (quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              strings.noQuotesFound,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        final quote = quotes[index];
        final key = _keyFor(quote.id);
        final height = _cardHeight(quote, isSinhala);
        final displayText = isSinhala
            ? (quote.textSi ?? quote.text)
            : quote.text;
        final displayAuthor = isSinhala
            ? (quote.authorSi ?? quote.author)
            : quote.author;
        return GestureDetector(
          onTap: () => _showQuoteDetail(quote, key, strings),
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              height: height,
              child: _QuoteCard(
                quote: quote,
                displayText: displayText,
                displayAuthor: displayAuthor,
                onDownload: () => _downloadCard(key, quote, strings),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Quote Detail Bottom Sheet ────────────────────────────────────────────────

class _QuoteDetailSheet extends StatelessWidget {
  final Quote quote;
  final VoidCallback onDownload;
  const _QuoteDetailSheet({required this.quote, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final strings = LanguageProvider.of(context);
    final isSinhala = strings.isSinhala;
    final displayText = isSinhala ? (quote.textSi ?? quote.text) : quote.text;
    final displayAuthor = isSinhala
        ? (quote.authorSi ?? quote.author)
        : quote.author;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // The actual card preview — full visual rendering
          AspectRatio(
            aspectRatio: 1.0,
            child: _QuoteCard(
              quote: quote,
              displayText: displayText,
              displayAuthor: displayAuthor,
              onDownload: onDownload,
            ),
          ),
          const SizedBox(height: 20),
          // Author + category row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _kTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  quote.category.toUpperCase(),
                  style: const TextStyle(
                    color: _kTeal,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Download button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onDownload();
              },
              icon: const Icon(Icons.download_rounded),
              label: Text(strings.saveQuote),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card widgets ─────────────────────────────────────────────────────────────

class _QuoteCard extends StatelessWidget {
  final Quote quote;
  final String displayText;
  final String displayAuthor;
  final VoidCallback onDownload;
  const _QuoteCard({
    required this.quote,
    required this.displayText,
    required this.displayAuthor,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    if (quote.imageUrl != null)
      return _ImageCard(
        quote: quote,
        displayText: displayText,
        displayAuthor: displayAuthor,
        onDownload: onDownload,
      );
    switch (quote.style) {
      case QuoteStyle.colored:
      case QuoteStyle.dark:
      case QuoteStyle.bold:
        return _GradientCard(
          quote: quote,
          displayText: displayText,
          displayAuthor: displayAuthor,
          onDownload: onDownload,
        );
      case QuoteStyle.aesthetic:
        return _AestheticCard(
          quote: quote,
          displayText: displayText,
          displayAuthor: displayAuthor,
          onDownload: onDownload,
        );
      case QuoteStyle.minimal:
        return _MinimalCard(
          quote: quote,
          displayText: displayText,
          displayAuthor: displayAuthor,
          onDownload: onDownload,
        );
    }
  }
}

class _ImageCard extends StatelessWidget {
  final Quote quote;
  final String displayText;
  final String displayAuthor;
  final VoidCallback onDownload;
  const _ImageCard({
    required this.quote,
    required this.displayText,
    required this.displayAuthor,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            quote.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: quote.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xBB000000), Color(0x88000000)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '\u201C',
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 12,
            right: 12,
            child: Text(
              '— $displayAuthor',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 10,
                fontStyle: FontStyle.italic,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 8,
            child: GestureDetector(
              onTap: onDownload,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientCard extends StatelessWidget {
  final Quote quote;
  final String displayText;
  final String displayAuthor;
  final VoidCallback onDownload;
  const _GradientCard({
    required this.quote,
    required this.displayText,
    required this.displayAuthor,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: quote.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: quote.colors.first.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 8,
            child: Text(
              '\u201C',
              style: TextStyle(
                fontSize: 52,
                color: Colors.white.withValues(alpha: 0.25),
                height: 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 24, 12, 34),
            child: Center(
              child: Text(
                displayText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            left: 12,
            right: 12,
            child: Text(
              '— $displayAuthor',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 8,
            child: GestureDetector(
              onTap: onDownload,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AestheticCard extends StatelessWidget {
  final Quote quote;
  final String displayText;
  final String displayAuthor;
  final VoidCallback onDownload;
  const _AestheticCard({
    required this.quote,
    required this.displayText,
    required this.displayAuthor,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: quote.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 8,
            child: Text(
              '\u201C',
              style: TextStyle(
                fontSize: 44,
                color: Colors.black.withValues(alpha: 0.07),
                height: 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 22, 12, 34),
            child: Center(
              child: Text(
                displayText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF3D3D3D),
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            left: 12,
            right: 12,
            child: Text(
              '— $displayAuthor',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 8,
            child: GestureDetector(
              onTap: onDownload,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.download_rounded,
                  color: Color(0xFF555555),
                  size: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalCard extends StatelessWidget {
  final Quote quote;
  final String displayText;
  final String displayAuthor;
  final VoidCallback onDownload;
  const _MinimalCard({
    required this.quote,
    required this.displayText,
    required this.displayAuthor,
    required this.onDownload,
  });

  Color get _accentColor {
    final hex = quote.accent;
    if (hex == null) return _kTeal;
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 12, 34),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayText,
                  style: const TextStyle(
                    color: Color(0xFF212121),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 18,
            left: 14,
            right: 12,
            child: Text(
              '— $displayAuthor',
              style: TextStyle(
                color: _accentColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 8,
            child: GestureDetector(
              onTap: onDownload,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.download_rounded,
                  color: _accentColor,
                  size: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
