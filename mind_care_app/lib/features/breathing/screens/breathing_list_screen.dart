import 'package:flutter/material.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
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
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: isDark ? Colors.white : const Color(0xFF1A4A4A),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Text(
                    s.mindBreath,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A4A4A),
                    ),
                  ),
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
              BoxShadow(
                color: const Color(0xFF00796B).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('🪷', style: TextStyle(fontSize: 44)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.buddhistMeditations,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${kMeditations.length} ${s.meditationsTab} • ${s.howYouWillPractice}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Text(
            s.choosePractice,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : const Color(0xFF2A5A5A),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: kMeditations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _MeditationCard(
              data: kMeditations[i],
              isDark: isDark,
              s: s,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MeditationSessionScreen(meditation: kMeditations[i]),
                ),
              ),
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
  const _MeditationCard({
    required this.data,
    required this.isDark,
    required this.s,
    required this.onTap,
  });

  Color get _levelColor {
    switch (data.level) {
      case 'Intermediate':
        return const Color(0xFFF9A825);
      case 'Advanced':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF43A047);
    }
  }

  String _levelLabel(dynamic s) {
    switch (data.level) {
      case 'Intermediate':
        return s.intermediate;
      case 'Advanced':
        return s.advanced;
      default:
        return s.beginner;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gradient strip
            Container(
              width: 76,
              height: 88,
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
              child: Center(
                child: Text(data.emoji, style: const TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A3333),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _levelColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _levelLabel(s),
                            style: TextStyle(
                              fontSize: 9,
                              color: _levelColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.pali,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.localDescription(s.isSinhala),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF4A6A6A),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          data.duration,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.format_list_numbered_rounded,
                          size: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${data.steps.length} ${s.steps}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.play_circle_rounded,
                color: data.gradient[1],
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
