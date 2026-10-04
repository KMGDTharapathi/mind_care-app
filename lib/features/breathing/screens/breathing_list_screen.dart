import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/data/models/breathing_pattern.dart';
import 'package:mind_care_app/data/repositories/breathing_repository.dart';
import 'package:mind_care_app/features/meditation/screens/meditation_list_screen.dart';
import 'package:mind_care_app/features/meditation/screens/meditation_session_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  HUB — two tabs: Meditations + Breathing Exercises
// ─────────────────────────────────────────────────────────────────────────────
class BreathingListScreen extends StatefulWidget {
  const BreathingListScreen({super.key});
  @override
  State<BreathingListScreen> createState() => _BreathingListScreenState();
}

class _BreathingListScreenState extends State<BreathingListScreen>
    with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1A1A) : const Color(0xFFF0F9F9);
    final s = LanguageProvider.of(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: isDark ? Colors.white : const Color(0xFF1A4A4A)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Text(s.mindBreath,
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1A4A4A))),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // ── Meditations only ─────────────────────────────────────────────
            Expanded(
              child: _MeditationsTab(isDark: isDark, s: s),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MEDITATIONS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _MeditationsTab extends StatelessWidget {
  final bool isDark;
  final dynamic s;
  const _MeditationsTab({required this.isDark, required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4DB6AC), Color(0xFF00796B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: const Color(0xFF00796B).withOpacity(0.3),
                  blurRadius: 14, offset: const Offset(0, 5)),
            ],
          ),
          child: Row(children: [
            const Text('🪷', style: TextStyle(fontSize: 44)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.buddhistMeditations,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 3),
                Text('${kMeditations.length} ${s.meditationsTab} • ${s.howYouWillPractice}',
                    style: TextStyle(fontSize: 12,
                        color: Colors.white.withOpacity(0.85))),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Text(s.choosePractice,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : const Color(0xFF2A5A5A))),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: kMeditations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _MeditationCard(
              data: kMeditations[i],
              isDark: isDark,
              s: s,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                      MeditationSessionScreen(meditation: kMeditations[i]))),
            ),
          ),
        ),
      ],
    );
  }
}

class _MeditationCard extends StatelessWidget {
  final MeditationData data;
  final bool isDark;
  final dynamic s;
  final VoidCallback onTap;
  const _MeditationCard({required this.data, required this.isDark, required this.s, required this.onTap});

  Color get _levelColor {
    switch (data.level) {
      case 'Intermediate': return const Color(0xFFF9A825);
      case 'Advanced': return const Color(0xFFE53935);
      default: return const Color(0xFF43A047);
    }
  }

  String _levelLabel(dynamic s) {
    switch (data.level) {
      case 'Intermediate': return s.intermediate;
      case 'Advanced': return s.advanced;
      default: return s.beginner;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05),
                blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            // Gradient strip
            Container(
              width: 76, height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: data.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
              child: Center(child: Text(data.emoji,
                  style: const TextStyle(fontSize: 34))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(data.name,
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1A3333))),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _levelColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(_levelLabel(s),
                            style: TextStyle(fontSize: 9,
                                color: _levelColor, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                    ]),
                    const SizedBox(height: 2),
                    Text(data.pali,
                        style: TextStyle(fontSize: 10,
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 4),
                    Text(data.localDescription(s.isSinhala),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11,
                            color: isDark ? Colors.white54 : const Color(0xFF4A6A6A),
                            height: 1.4)),
                    const SizedBox(height: 5),
                    Row(children: [
                      Icon(Icons.timer_outlined, size: 11,
                          color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(width: 3),
                      Text(data.duration,
                          style: TextStyle(fontSize: 10,
                              color: isDark ? Colors.white38 : Colors.black38)),
                      const SizedBox(width: 10),
                      Icon(Icons.format_list_numbered_rounded, size: 11,
                          color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(width: 3),
                      Text('${data.steps.length} ${s.steps}',
                          style: TextStyle(fontSize: 10,
                              color: isDark ? Colors.white38 : Colors.black38)),
                    ]),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.play_circle_rounded,
                  color: data.gradient[1], size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BREATHING TAB
// ─────────────────────────────────────────────────────────────────────────────
class _BreathingTab extends StatelessWidget {
  final bool isDark;
  final dynamic s;
  const _BreathingTab({required this.isDark, required this.s});

  String _phaseSummary(List<BreathingPhase> phases) =>
      phases.map((p) => '${p.label} ${p.durationSeconds}s').join(' → ');

  // Metadata for each breathing pattern — localized
  static Map<String, ({String emoji, Color color, String desc, String benefit})> _getMeta(dynamic s) => {
    'box': (emoji: '📦', color: const Color(0xFF0288D1), desc: s.boxBreathingDesc, benefit: s.boxBreathingBenefit),
    '478': (emoji: '😴', color: const Color(0xFF7B1FA2), desc: s.breathing478Desc, benefit: s.breathing478Benefit),
    'deep-calm': (emoji: '🌊', color: const Color(0xFF00796B), desc: s.deepCalmDesc, benefit: s.deepCalmBenefit),
  };

  static Map<String, String> _getPatternNames(dynamic s) => {
    'box': s.boxBreathingName,
    '478': s.breathing478Name,
    'deep-calm': s.deepCalmName,
  };

  String _localPhaseLabel(String label, dynamic s) {
    switch (label) {
      case 'Inhale': return s.phaseInhale;
      case 'Hold': return s.phaseHold;
      case 'Exhale': return s.phaseExhale;
      default: return label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final patterns = BreathingRepository().getAll();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: const Color(0xFF0288D1).withOpacity(0.3),
                  blurRadius: 14, offset: const Offset(0, 5)),
            ],
          ),
          child: Row(children: [
            const Text('🌬️', style: TextStyle(fontSize: 44)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.breathingExercises,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 3),
                Text('${patterns.length} ${s.breathingTab} • ${s.howYouWillPractice}',
                    style: TextStyle(fontSize: 12,
                        color: Colors.white.withOpacity(0.85))),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Text(s.chooseTechnique,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : const Color(0xFF2A5A5A))),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: patterns.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final p = patterns[i];
              final meta = _getMeta(s);
              final names = _getPatternNames(s);
              final m = meta[p.id];
              final color = m?.color ?? const Color(0xFF5BA8A0);
              final emoji = m?.emoji ?? '🌬️';
              final benefit = m?.benefit ?? '';
              final desc = m?.desc ?? p.description;
              final name = names[p.id] ?? p.name;
              return _BreathingCard(
                pattern: p,
                localName: name,
                localDesc: desc,
                color: color,
                emoji: emoji,
                benefit: benefit,
                phaseSummary: _phaseSummary(p.phases),
                localPhaseLabel: (label) => _localPhaseLabel(label, s),
                isDark: isDark,
                onTap: () => context.push('/breathing/${p.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BreathingCard extends StatelessWidget {
  final BreathingPattern pattern;
  final String localName;
  final String localDesc;
  final Color color;
  final String emoji;
  final String benefit;
  final String phaseSummary;
  final String Function(String) localPhaseLabel;
  final bool isDark;
  final VoidCallback onTap;

  const _BreathingCard({
    required this.pattern, required this.localName, required this.localDesc,
    required this.color, required this.emoji,
    required this.benefit, required this.phaseSummary,
    required this.localPhaseLabel,
    required this.isDark, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05),
                blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            // Color strip
            Container(
              width: 76, height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
              child: Center(child: Text(emoji,
                  style: const TextStyle(fontSize: 34))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(localName,
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1A3333))),
                      ),
                      if (benefit.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(benefit,
                              style: TextStyle(fontSize: 9,
                                  color: color, fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(width: 8),
                    ]),
                    const SizedBox(height: 4),
                    Text(localDesc,
                        style: TextStyle(fontSize: 11,
                            color: isDark ? Colors.white54 : const Color(0xFF4A6A6A))),
                    const SizedBox(height: 6),
                    // Phase chips
                    Wrap(
                      spacing: 4, runSpacing: 4,
                      children: pattern.phases.map((ph) {
                        final phColor = ph.label == 'Inhale'
                            ? const Color(0xFF43A047)
                            : ph.label == 'Exhale'
                                ? const Color(0xFF0288D1)
                                : const Color(0xFFF9A825);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: phColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${localPhaseLabel(ph.label)} ${ph.durationSeconds}s',
                              style: TextStyle(fontSize: 9,
                                  color: phColor, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.play_circle_rounded, color: color, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}
