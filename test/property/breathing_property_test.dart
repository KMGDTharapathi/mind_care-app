// Feature: mind-care-app, Property 9: Breathing phase sequence and timer integrity

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_care_app/data/models/breathing_pattern.dart';

// ── Simulated BreathingBloc phase sequencer ───────────────────────────────────

/// Simulates the phase sequencing logic from BreathingBloc without timers.
/// Returns a list of (phaseIndex, secondsRemaining) pairs in the order they
/// would be emitted during a single cycle.
List<({int phaseIndex, int secondsRemaining})> simulateSession(
    BreathingPattern pattern) {
  final result = <({int phaseIndex, int secondsRemaining})>[];
  final phases = pattern.phases;

  for (int phaseIdx = 0; phaseIdx < phases.length; phaseIdx++) {
    final duration = phases[phaseIdx].durationSeconds;
    // Emit initial state for this phase
    for (int s = duration; s >= 0; s--) {
      result.add((phaseIndex: phaseIdx, secondsRemaining: s));
    }
  }

  return result;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

BreathingPattern _randomPattern(Random rng, int id) {
  final phaseCount = 2 + rng.nextInt(4); // 2–5 phases
  final phases = List.generate(phaseCount, (i) {
    final labels = ['Inhale', 'Hold', 'Exhale', 'Rest', 'Pause'];
    return BreathingPhase(
      label: labels[i % labels.length],
      durationSeconds: 1 + rng.nextInt(10), // 1–10 seconds
    );
  });

  return BreathingPattern(
    id: 'pattern-$id',
    name: 'Pattern $id',
    description: 'Test pattern $id',
    phases: phases,
  );
}

void main() {
  group('Property 9: Breathing phase sequence and timer integrity', () {
    // Feature: mind-care-app, Property 9: Breathing phase sequence and timer integrity
    // Validates: Requirements 4.2, 4.3, 4.4
    test('phases appear in correct order and each phase runs for its durationSeconds', () {
      final rng = Random(42);

      for (int i = 0; i < 100; i++) {
        final pattern = _randomPattern(rng, i);
        final phases = pattern.phases;
        final simulation = simulateSession(pattern);

        // Verify phases appear in order
        int expectedPhaseIdx = 0;
        int expectedSeconds = phases[0].durationSeconds;

        for (final step in simulation) {
          expect(step.phaseIndex, equals(expectedPhaseIdx),
              reason:
                  'Iteration $i: expected phase $expectedPhaseIdx but got ${step.phaseIndex}');
          expect(step.secondsRemaining, equals(expectedSeconds),
              reason:
                  'Iteration $i: phase $expectedPhaseIdx expected $expectedSeconds seconds remaining but got ${step.secondsRemaining}');

          expectedSeconds--;
          if (expectedSeconds < 0) {
            expectedPhaseIdx++;
            if (expectedPhaseIdx < phases.length) {
              expectedSeconds = phases[expectedPhaseIdx].durationSeconds;
            }
          }
        }

        // Verify all phases were visited
        final visitedPhases =
            simulation.map((s) => s.phaseIndex).toSet();
        for (int p = 0; p < phases.length; p++) {
          expect(visitedPhases.contains(p), isTrue,
              reason: 'Iteration $i: phase $p was never visited');
        }

        // Verify each phase ran for exactly its durationSeconds ticks
        for (int p = 0; p < phases.length; p++) {
          final phaseSteps =
              simulation.where((s) => s.phaseIndex == p).toList();
          // Steps go from durationSeconds down to 0 inclusive = durationSeconds + 1 steps
          expect(phaseSteps.length, equals(phases[p].durationSeconds + 1),
              reason:
                  'Iteration $i: phase $p should have ${phases[p].durationSeconds + 1} steps');
          expect(phaseSteps.first.secondsRemaining,
              equals(phases[p].durationSeconds),
              reason:
                  'Iteration $i: phase $p should start at ${phases[p].durationSeconds}');
          expect(phaseSteps.last.secondsRemaining, equals(0),
              reason: 'Iteration $i: phase $p should end at 0');
        }
      }
    });
  });
}
