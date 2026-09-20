import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';

class WordPuzzleGame extends StatefulWidget {
  const WordPuzzleGame({super.key});

  @override
  State<WordPuzzleGame> createState() => _WordPuzzleGameState();
}

class _WordPuzzleGameState extends State<WordPuzzleGame>
    with SingleTickerProviderStateMixin {
  // Word lists for different languages
  static const List<String> _englishWords = [
    'CALM', 'PEACE', 'RELAX', 'BREATHE', 'ZEN', 'SERENE', 'TRANQUIL', 'SOOTHE',
    'MINDFUL', 'BALANCE', 'HARMONY', 'STILLNESS', 'CLARITY', 'FOCUS', 'PRESENT',
    'AWARE', 'CENTERED', 'GROUNDED', 'FLOW', 'EASE', 'COMFORT', 'HEALING',
    'RESTORE', 'RENEW', 'REFRESH', 'REJUVENATE', 'RELAXED', 'PEACEFUL',
  ];

  static const List<String> _sinhalaWords = [
    'සන්සුන්', 'සාමය', 'සාන්ති', 'සුන්දර', 'සුඛ', 'සතුටු', 'සුමති',
    'ශාන්ත', 'ප්‍රශාන්ත', 'නිවෘත්ති', 'සිත් සාමය', 'මනස් සාමය',
    'ස්වාධීන', 'නිරාමය', 'සාර්ථක', 'සම්පූර්ණ', 'සමාර්ථය',
  ];

  String _targetWord = '';
  List<String> _scrambledLetters = [];
  List<String> _selectedLetters = [];
  int _score = 0;
  int _level = 1;
  int _wordsFound = 0;
  int _streak = 0;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _newWord();
  }

  void _newWord() {
    final words = LanguageProvider.of(context).isSinhala ? _sinhalaWords : _englishWords;
    _targetWord = words[_random.nextInt(words.length)];
    _scrambleWord();
    _selectedLetters = [];
  }

  void _scrambleWord() {
    _scrambledLetters = _targetWord.split('');
    // Fisher-Yates shuffle
    for (int i = _scrambledLetters.length - 1; i > 0; i--) {
      final j = math.Random().nextInt(i + 1);
      final temp = _scrambledLetters[i];
      _scrambledLetters[i] = _scrambledLetters[j];
      _scrambledLetters[j] = temp;
    }
  }

  void _onLetterTap(int index) {
    if (_selectedLetters.length >= _targetWord.length) return;

    setState(() {
      _selectedLetters.add(_scrambledLetters[index]);
      _scrambledLetters.removeAt(index);

      if (_selectedLetters.length == _targetWord.length) {
        _checkWord();
      }
    });
  }

  void _onSelectedTap(int index) {
    setState(() {
      _scrambledLetters.add(_selectedLetters[index]);
      _selectedLetters.removeAt(index);
    });
  }

  void _checkWord() {
    final userWord = _selectedLetters.join('');
    if (userWord == _targetWord) {
      _onCorrectWord();
    } else {
      _onWrongWord();
    }
  }

  void _onCorrectWord() {
    final basePoints = _targetWord.length * 10;
    final streakBonus = (_streak + 1) * 5;
    final levelBonus = _level * 5;
    final points = basePoints + streakBonus + levelBonus;

    setState(() {
      _score += points + streakBonus;
      _streak++;
      _wordsFound++;

      if (_wordsFound % 5 == 0) {
        _level++;
      }
    });

    // Show success and get new word
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(_newWord);
      }
    });
  }

  void _onWrongWord() {
    // Return letters to pool
    setState(() {
      _scrambledLetters.addAll(_selectedLetters);
      _selectedLetters = [];
      _streak = 0;
      // Shuffle again
      _scrambleWord();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A2A0A) : const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: Text(s.gameWordPuzzleTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A2A0A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: LeafBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Stats bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatChip(
                      icon: Icons.star_rounded,
                      label: s.isSinhala ? 'ලකුණු' : 'Score',
                      value: '$_score',
                      color: const Color(0xFF8BC34A),
                      isDark: isDark,
                    ),
                    _StatChip(
                      icon: Icons.layers_rounded,
                      label: s.isSinhala ? 'මට්ටම' : 'Level',
                      value: '$_level',
                      color: const Color(0xFF8BC34A),
                      isDark: isDark,
                    ),
                    _StatChip(
                      icon: Icons.local_fire_department_rounded,
                      label: s.isSinhala ? 'පෙරපුර' : 'Streak',
                      value: '$_streak',
                      color: const Color(0xFFFFC107),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              // Target word hint
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A2A0A).withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF8BC34A).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        s.isSinhala ? 'ශබ්දය හඳුනාගන්න' : 'Guess the Word',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_targetWord.length} ${s.isSinhala ? 'අකුරු' : 'Letters'}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8BC34A),
                          letterSpacing: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Selected letters (building area)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedLetters.length == _targetWord.length
                          ? const Color(0xFF8BC34A)
                          : const Color(0xFF8BC34A).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_targetWord.length, (index) {
                      if (index < _selectedLetters.length) {
                        return _LetterTile(
                          letter: _selectedLetters[index],
                          isSelected: true,
                          onTap: () => _onSelectedTap(index),
                        );
                      } else {
                        return _LetterTile(
                          letter: '_',
                          isSelected: false,
                          isEmpty: true,
                          onTap: null,
                        );
                      }
                    }),
                  ),
                ),
              ),

              // Scrambled letters (pool)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        s.isSinhala ? 'අකුරු තෝරන්න' : 'Tap Letters',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _scrambledLetters.length,
                          itemBuilder: (_, index) => _LetterTile(
                            letter: _scrambledLetters[index],
                            isSelected: false,
                            onTap: () => _onLetterTap(index),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatChip(
                      icon: Icons.menu_book_rounded,
                      label: s.isSinhala ? 'ශබ්ද' : 'Words',
                      value: '$_wordsFound',
                      color: const Color(0xFF8BC34A),
                      isDark: true,
                    ),
                    _StatChip(
                      icon: Icons.auto_awesome_rounded,
                      label: s.isSinhala ? 'අකුරු' : 'Letters',
                      value: '${_scrambledLetters.length + _selectedLetters.length}',
                      color: const Color(0xFF8BC34A),
                      isDark: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  final String letter;
  final bool isSelected;
  final bool isEmpty;
  final VoidCallback? onTap;

  const _LetterTile({
    required this.letter,
    required this.isSelected,
    this.isEmpty = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isEmpty) {
      return Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
        child: Center(
          child: Text(
            '_',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8BC34A).withValues(alpha: 0.9),
              const Color(0xFF689F38),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8BC34A).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}