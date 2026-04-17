import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'package:mind_care_app/data/repositories/breathing_repository.dart';
import 'package:mind_care_app/features/breathing/bloc/breathing_bloc.dart';
import 'package:mind_care_app/features/breathing/widgets/animated_breath_circle.dart';
import 'package:mind_care_app/services/analytics/analytics_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.patternName)),
      body: BlocBuilder<BreathingBloc, BreathingState>(
        builder: (context, state) {
          if (state.isCompleted) {
            return _CompletionOverlay(
              onRepeat: () {
                final pattern = state.pattern!;
                context.read<BreathingBloc>()
                  ..add(ResetSession())
                  ..add(StartSession(pattern));
              },
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
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CompletionOverlay extends StatelessWidget {
  final VoidCallback onRepeat;
  final VoidCallback onGoHome;

  const _CompletionOverlay({required this.onRepeat, required this.onGoHome});

  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(s.wellDone,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onRepeat,
            child: Text(s.practiceAgain),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onGoHome,
            child: Text(s.navHome),
          ),
        ],
      ),
    );
  }
}
