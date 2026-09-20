import 'package:flutter/material.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/data/models/breathing_pattern.dart';
import 'package:mind_care_app/data/repositories/breathing_repository.dart';
import 'breathing_session_screen.dart';

class BreathingCustomizeScreen extends StatefulWidget {
  final String patternId;
  final bool isFirstRun;

  const BreathingCustomizeScreen({
    super.key,
    required this.patternId,
    this.isFirstRun = false,
  });

  @override
  State<BreathingCustomizeScreen> createState() =>
      _BreathingCustomizeScreenState();
}

class _BreathingCustomizeScreenState extends State<BreathingCustomizeScreen>
    with SingleTickerProviderStateMixin {
  late BreathingPattern _originalPattern;
  late BreathingPattern _customPattern;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    final repo = BreathingRepository();
    _originalPattern = repo.getById(widget.patternId)!;
    _customPattern = _originalPattern.copyWith(
      cycles: _originalPattern.cycles,
      phases: _originalPattern.phases
          .map(
            (p) => BreathingPhase(
              label: p.label,
              durationSeconds: p.durationSeconds,
            ),
          )
          .toList(),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _updatePhaseDuration(int index, int seconds) {
    if (seconds < 1) return;
    setState(() {
      final newPhases = List<BreathingPhase>.from(_customPattern.phases);
      newPhases[index] = BreathingPhase(
        label: newPhases[index].label,
        durationSeconds: seconds,
      );
      _customPattern = _customPattern.copyWith(phases: newPhases);
    });
  }

  void _updateCycles(int cycles) {
    if (cycles < 1) return;
    setState(() {
      _customPattern = _customPattern.copyWith(cycles: cycles);
    });
  }

  void _resetToDefault() {
    setState(() {
      _customPattern = _originalPattern.copyWith(
        cycles: _originalPattern.cycles,
        phases: _originalPattern.phases
            .map(
              (p) => BreathingPhase(
                label: p.label,
                durationSeconds: p.durationSeconds,
              ),
            )
            .toList(),
      );
    });
  }

  void _startSession() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BreathingSessionScreen(patternId: widget.patternId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D1A1A) : const Color(0xFFF0F9F9);
    final cardColor = isDark ? const Color(0xFF1A2A2A) : Colors.white;
    final primaryColor = const Color(0xFF5BA8A0);
    final accentColors = [
      const Color(0xFF5BA8A0),
      const Color(0xFF4DB6AC),
      const Color(0xFF00796B),
      const Color(0xFF26A69A),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(s.isSinhala ? 'හුස්ම සකස් කරන්න' : 'Customize Breathing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A4A4A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!widget.isFirstRun)
            TextButton.icon(
              onPressed: _resetToDefault,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                s.isSinhala ? 'මුල්' : 'Default',
                style: const TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, const Color(0xFF00796B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _customPattern.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.isFirstRun
                                    ? (s.isSinhala
                                          ? 'ඔබේ හුස්ම අභ්‍යාසය සකස් කරන්න'
                                          : 'Personalize your breathing practice')
                                    : (s.isSinhala
                                          ? 'අවස්ථා සදහා සකස් කරන්න'
                                          : 'Adjust for this session'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.repeat_rounded,
                          label:
                              '${_customPattern.cycles} ${s.isSinhala ? "චක්‍ර" : "Cycles"}',
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: Icons.timer_outlined,
                          label:
                              '${_customPattern.totalDurationSeconds}s ${s.isSinhala ? "කාලය" : "Total"}',
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: Icons.format_list_numbered_rounded,
                          label:
                              '${_customPattern.phases.length} ${s.isSinhala ? "පියවර" : "Phases"}',
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Cycles selector
              Text(
                s.isSinhala ? 'චක්‍ර සංඛ්‍යාව' : 'Cycles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A3333),
                ),
              ),
              const SizedBox(height: 12),
              _CycleSelector(
                cycles: _customPattern.cycles,
                onChanged: _updateCycles,
                isDark: isDark,
                accentColor: primaryColor,
              ),

              const SizedBox(height: 24),

              // Phase durations
              Text(
                s.isSinhala
                    ? 'පියවර කාලය (විනාඩි)'
                    : 'Phase Duration (seconds)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A3333),
                ),
              ),
              const SizedBox(height: 12),

              ..._customPattern.phases.asMap().entries.map((entry) {
                final index = entry.key;
                final phase = entry.value;
                final phaseColor = accentColors[index % accentColors.length];
                return _PhaseEditorCard(
                  index: index,
                  phase: phase,
                  phaseColor: phaseColor,
                  isDark: isDark,
                  onDurationChanged: (seconds) =>
                      _updatePhaseDuration(index, seconds),
                );
              }),

              const SizedBox(height: 24),

              // Total time summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryItem(
                      icon: Icons.timer_outlined,
                      label: s.isSinhala ? 'මුල් කාලය' : 'Original',
                      value: '${_originalPattern.totalDurationSeconds}s',
                      color: Colors.grey.shade600,
                      isDark: isDark,
                    ),
                    _SummaryItem(
                      icon: Icons.tune_rounded,
                      label: s.isSinhala ? 'සංස්කරණය' : 'Custom',
                      value: '${_customPattern.totalDurationSeconds}s',
                      color: primaryColor,
                      isDark: isDark,
                    ),
                    _SummaryItem(
                      icon: Icons.trending_up_rounded,
                      label: s.isSinhala ? 'වෙනස' : 'Change',
                      value:
                          _customPattern.totalDurationSeconds >
                              _originalPattern.totalDurationSeconds
                          ? '+${_customPattern.totalDurationSeconds - _originalPattern.totalDurationSeconds}s'
                          : '${_customPattern.totalDurationSeconds - _originalPattern.totalDurationSeconds}s',
                      color:
                          _customPattern.totalDurationSeconds >
                              _originalPattern.totalDurationSeconds
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Start button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: primaryColor.withValues(alpha: 0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.isFirstRun
                            ? (s.isSinhala ? 'ආරම්භ කරන්න' : 'Start Session')
                            : (s.isSinhala
                                  ? 'මෙම සංස්කරණය සඳහා ආරම්භ කරන්න'
                                  : 'Start with This Customization'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.play_arrow_rounded, size: 24),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick start with defaults
              if (!widget.isFirstRun)
                TextButton(
                  onPressed: () {
                    _resetToDefault();
                    Future.delayed(
                      const Duration(milliseconds: 300),
                      _startSession,
                    );
                  },
                  child: Text(
                    s.isSinhala
                        ? 'මුල් වර්ගයෙන් ඉදිරියට'
                        : 'Continue with Defaults',
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleSelector extends StatelessWidget {
  final int cycles;
  final ValueChanged<int> onChanged;
  final bool isDark;
  final Color accentColor;

  const _CycleSelector({
    required this.cycles,
    required this.onChanged,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CycleBtn(
                icon: Icons.remove_rounded,
                onTap: cycles > 1 ? () => onChanged(cycles - 1) : null,
                isDark: isDark,
                accentColor: accentColor,
              ),
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.15),
                      accentColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$cycles',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ),
              const SizedBox(width: 24),
              _CycleBtn(
                icon: Icons.add_rounded,
                onTap: cycles < 20 ? () => onChanged(cycles + 1) : null,
                isDark: isDark,
                accentColor: accentColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => onChanged(i * 2),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 44,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cycles == i * 2
                          ? accentColor
                          : isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cycles == i * 2
                            ? accentColor
                            : accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${i * 2}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: cycles == i * 2 ? Colors.white : accentColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CycleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;
  final Color accentColor;

  const _CycleBtn({
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: enabled
              ? accentColor.withValues(alpha: 0.12)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.shade100),
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? accentColor.withValues(alpha: 0.3)
                : (isDark ? Colors.white12 : Colors.grey.shade300),
          ),
        ),
        child: Icon(
          icon,
          color: enabled
              ? accentColor
              : (isDark ? Colors.white24 : Colors.grey.shade400),
          size: 26,
        ),
      ),
    );
  }
}

class _PhaseEditorCard extends StatelessWidget {
  final int index;
  final BreathingPhase phase;
  final Color phaseColor;
  final bool isDark;
  final ValueChanged<int> onDurationChanged;

  const _PhaseEditorCard({
    required this.index,
    required this.phase,
    required this.phaseColor,
    required this.isDark,
    required this.onDurationChanged,
  });

  String _localLabel(String label, BuildContext context) {
    final s = LanguageProvider.of(context);
    switch (label) {
      case 'Inhale':
        return s.phaseInhale;
      case 'Hold':
        return s.phaseHold;
      case 'Exhale':
        return s.phaseExhale;
      default:
        return label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _localLabel(phase.label, context);
    final icons = {
      'Inhale': Icons.arrow_downward_rounded,
      'Hold': Icons.pause_circle_rounded,
      'Exhale': Icons.arrow_upward_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: phaseColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: phaseColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Phase indicator
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  phaseColor.withValues(alpha: 0.2),
                  phaseColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: phaseColor.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Icon(
                icons[phase.label] ?? Icons.air_rounded,
                color: phaseColor,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: phaseColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}. $label',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: phaseColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      phase.label == 'Hold'
                          ? (LanguageProvider.of(context).isSinhala
                                ? 'රඳවන්න'
                                : 'Hold')
                          : phase.label == 'Inhale'
                          ? (LanguageProvider.of(context).isSinhala
                                ? 'ගන්න'
                                : 'Inhale')
                          : (LanguageProvider.of(context).isSinhala
                                ? 'හෙළන්න'
                                : 'Exhale'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Duration slider
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 6,
                          activeTrackColor: phaseColor,
                          inactiveTrackColor: phaseColor.withValues(
                            alpha: 0.15,
                          ),
                          thumbColor: phaseColor,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                          ),
                          overlayColor: phaseColor.withValues(alpha: 0.15),
                          valueIndicatorColor: phaseColor,
                          valueIndicatorTextStyle: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        child: Slider(
                          value: phase.durationSeconds.toDouble(),
                          min: 1,
                          max: 20,
                          divisions: 19,
                          label: '${phase.durationSeconds}s',
                          onChanged: (v) => onDurationChanged(v.round()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 56,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: phaseColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: phaseColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${phase.durationSeconds}s',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: phaseColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
