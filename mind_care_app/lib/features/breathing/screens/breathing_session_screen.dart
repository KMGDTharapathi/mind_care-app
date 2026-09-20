import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/data/repositories/breathing_repository.dart';
import 'package:mind_care_app/features/breathing/bloc/breathing_bloc.dart';
import 'package:mind_care_app/features/breathing/widgets/animated_breath_circle.dart';
import 'package:mind_care_app/services/analytics/analytics_service.dart';
import 'breathing_customize_screen.dart';

class BreathingSessionScreen extends StatelessWidget {
  final String patternId;
  final AnalyticsService? analyticsService;

  const BreathingSessionScreen({
    super.key,
    required this.patternId,
    this.analyticsService,
  });

  @override
  Widget build(BuildContext context) {
    final pattern = BreathingRepository().getById(patternId);
    final s = LanguageProvider.of(context);
    if (pattern == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Pattern not found')),
      );
    }
    // Use localized name for the pattern
    final localName = {
      'box': s.boxBreathingName,
      '478': s.breathing478Name,
      'deep-calm': s.deepCalmName,
    }[patternId] ?? pattern.name;

    return BlocProvider(
      create: (_) => BreathingBloc(analyticsService: analyticsService)
        ..add(StartSession(pattern)),
      child: _BreathingSessionView(patternName: localName),
    );
  }
}

class _BreathingSessionView extends StatefulWidget {
  final String patternName;
  const _BreathingSessionView({required this.patternName});

  @override
  State<_BreathingSessionView> createState() => _BreathingSessionViewState();
}

class _BreathingSessionViewState extends State<_BreathingSessionView> {
  @override
  void initState() {
    super.initState();
    try {
      WakelockPlus.enable();
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      WakelockPlus.disable();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _confirmEnd() async {
    final s = LanguageProvider.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.endSessionTitle),
        content: Text(s.endSessionContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.stay),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.leave),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<BreathingBloc>().add(ResetSession());
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.patternName)),
      body: BlocBuilder<BreathingBloc, BreathingState>(
        builder: (context, state) {
          if (state.isCompleted) {
            return _CompletionOverlay(
              patternId: state.pattern!.id,
              onGoHome: () => context.go('/home'),
            );
          }

          if (state.pattern == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final phases = state.pattern!.phases;
          final phase = phases[state.currentPhaseIndex];
          final label = phase.label;
          final isInhale = label == 'Inhale';
          final isHold = label == 'Hold';
          final s = LanguageProvider.of(context);

          String localLabel(String l) {
            switch (l) {
              case 'Inhale': return s.phaseInhale;
              case 'Hold': return s.phaseHold;
              case 'Exhale': return s.phaseExhale;
              default: return l;
            }
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBreathCircle(
                  phaseLabel: label,
                  isInhale: isInhale,
                  isHold: isHold,
                  durationSeconds: phase.durationSeconds,
                  isPaused: !state.isRunning,
                ),
                const SizedBox(height: 24),
                Text(
                  localLabel(label),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.secondsRemaining}s',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 16),
                Text(
                  s.isSinhala
                      ? 'චක්‍රය ${state.currentCycle} / ${state.totalCycles}'
                      : 'Cycle ${state.currentCycle} of ${state.totalCycles}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (!state.isRunning) ...[
                  const SizedBox(height: 8),
                  Text(
                    s.paused,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF5BA8A0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.read<BreathingBloc>().add(
                        state.isRunning ? PauseSession() : ResumeSession(),
                      ),
                      icon: Icon(
                        state.isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        state.isRunning ? s.pause : s.resume,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5BA8A0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _confirmEnd,
                      icon: const Icon(Icons.stop_rounded),
                      label: Text(s.endSession),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5BA8A0),
                        side: const BorderSide(color: Color(0xFF5BA8A0)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CompletionOverlay extends StatefulWidget {
  final String patternId;
  final VoidCallback onGoHome;

  const _CompletionOverlay({
    required this.patternId,
    required this.onGoHome,
  });

  @override
  State<_CompletionOverlay> createState() => _CompletionOverlayState();
}

class _CompletionOverlayState extends State<_CompletionOverlay> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate to customize screen after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BreathingCustomizeScreen(
              patternId: widget.patternId,
              isFirstRun: false,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF5BA8A0);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A3A3A), const Color(0xFF0D2A2A)]
                : [Colors.white, const Color(0xFFF0F9F9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, const Color(0xFF00796B)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              s.wellDone,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A3333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.isSinhala
                  ? 'ඔබ සාර්ථකව පුරා කළා!'
                  : 'You\'ve completed the session!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.isSinhala
                  ? 'සංස්කරණ සඳහා යන්න...'
                  : 'Going to customization...',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 12),
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BA8A0)),
            ),
          ],
        ),
      ),
    );
  }
}