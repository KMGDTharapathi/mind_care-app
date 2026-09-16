import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/core/router/app_router.dart';
import 'package:mind_care_app/core/theme/app_colors.dart';
import 'package:mind_care_app/data/local/hive_service.dart';
import 'package:mind_care_app/data/models/mood_entry.dart';
import 'package:mind_care_app/main.dart' show appLanguage;
import 'package:uuid/uuid.dart';

class MoodCheckinScreen extends StatefulWidget {
  final String lang;
  const MoodCheckinScreen({super.key, this.lang = 'en'});

  @override
  State<MoodCheckinScreen> createState() => _MoodCheckinScreenState();
}

class _MoodCheckinScreenState extends State<MoodCheckinScreen> {
  int? _selectedIndex;

  bool get _isSinhala => appLanguage.value.isSinhala;

  List<_MoodOption> get _moods => _isSinhala
      ? const [
          _MoodOption('😄', 'අපූරුයි', MoodType.excited, Color(0xFFFFE066)),
          _MoodOption('😊', 'හොඳයි', MoodType.happy, Color(0xFFA8E6CF)),
          _MoodOption('😌', 'සාමාන්‍යයි', MoodType.calm, Color(0xFFB8D4E8)),
          _MoodOption('😔', 'අඩුයි', MoodType.sad, Color(0xFFD4B8E8)),
          _MoodOption('😰', 'කනස්සල්ලෙන්', MoodType.anxious, Color(0xFFFFB8B8)),
        ]
      : const [
          _MoodOption('😄', 'Amazing', MoodType.excited, Color(0xFFFFE066)),
          _MoodOption('😊', 'Good', MoodType.happy, Color(0xFFA8E6CF)),
          _MoodOption('😌', 'Okay', MoodType.calm, Color(0xFFB8D4E8)),
          _MoodOption('😔', 'Low', MoodType.sad, Color(0xFFD4B8E8)),
          _MoodOption('😰', 'Anxious', MoodType.anxious, Color(0xFFFFB8B8)),
        ];

  Future<void> _saveMood(int index) async {
    setState(() => _selectedIndex = index);
    final mood = _moods[index];

    try {
      final entry = MoodEntry(
        id: const Uuid().v4(),
        mood: mood.type,
        timestamp: DateTime.now(),
      );
      await HiveService.moodEntries.put(entry.id, entry);
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted)
      context.go('${AppRouter.home}?lang=${appLanguage.value.languageCode}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.onboardingGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(),
                // Gentle greeting
                const Text('✨', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 20),
                Text(
                  _isSinhala
                      ? 'දැන් ඔබට\nහැඟෙන්නේ කෙසේද?'
                      : 'How are you\nfeeling right now?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSinhala
                      ? 'නිවැරදි හෝ වැරදි පිළිතුරක් නැත — ඔබටම අවංක වන්න 💚'
                      : 'No right or wrong answer — just be honest with yourself 💚',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                // Mood options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_moods.length, (i) {
                    final mood = _moods[i];
                    final isSelected = _selectedIndex == i;
                    return GestureDetector(
                      onTap: () => _saveMood(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 68 : 58,
                        height: isSelected ? 68 : 58,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? mood.color
                              : Colors.white.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: mood.color.withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            mood.emoji,
                            style: TextStyle(fontSize: isSelected ? 32 : 26),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                // Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _moods.map((m) {
                    return SizedBox(
                      width: 58,
                      child: Text(
                        m.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryDark.withValues(
                            alpha: 0.7,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const Spacer(),
                // Skip option — gentle, not prominent
                TextButton(
                  onPressed: () => context.go(
                    '${AppRouter.home}?lang=${appLanguage.value.languageCode}',
                  ),
                  child: Text(
                    _isSinhala ? 'පසුව සමහරවිට' : 'Maybe later',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondaryDark.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodOption {
  final String emoji;
  final String label;
  final MoodType type;
  final Color color;

  const _MoodOption(this.emoji, this.label, this.type, this.color);
}
