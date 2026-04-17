import 'package:mind_care_app/data/models/breathing_pattern.dart';

class BreathingRepository {
  List<BreathingPattern> getAll() => [
        BreathingPattern(
          id: 'box',
          name: 'Box Breathing',
          description: 'Equal breathing for focus and calm',
          phases: [
            BreathingPhase(label: 'Inhale', durationSeconds: 4),
            BreathingPhase(label: 'Hold', durationSeconds: 4),
            BreathingPhase(label: 'Exhale', durationSeconds: 4),
            BreathingPhase(label: 'Hold', durationSeconds: 4),
          ],
        ),
        BreathingPattern(
          id: '478',
          name: '4-7-8 Breathing',
          description: 'Relaxation technique for anxiety and sleep',
          phases: [
            BreathingPhase(label: 'Inhale', durationSeconds: 4),
            BreathingPhase(label: 'Hold', durationSeconds: 7),
            BreathingPhase(label: 'Exhale', durationSeconds: 8),
          ],
        ),
        BreathingPattern(
          id: 'deep-calm',
          name: 'Deep Calm',
          description: 'Deep diaphragmatic breathing for stress relief',
          phases: [
            BreathingPhase(label: 'Inhale', durationSeconds: 5),
            BreathingPhase(label: 'Hold', durationSeconds: 2),
            BreathingPhase(label: 'Exhale', durationSeconds: 7),
          ],
        ),
      ];

  BreathingPattern? getById(String id) {
    try {
      return getAll().firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
