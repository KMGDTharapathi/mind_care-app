import 'package:hive/hive.dart';

part 'breathing_pattern.g.dart';

@HiveType(typeId: 4)
class BreathingPhase extends HiveObject {
  @HiveField(0)
  final String label;

  @HiveField(1)
  final int durationSeconds;

  BreathingPhase({
    required this.label,
    required this.durationSeconds,
  });

  BreathingPhase copyWith({
    String? label,
    int? durationSeconds,
  }) {
    return BreathingPhase(
      label: label ?? this.label,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}

@HiveType(typeId: 5)
class BreathingPattern extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final List<BreathingPhase> phases;

  @HiveField(4)
  final int cycles;

  BreathingPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.phases,
    this.cycles = 1,
  });

  int get totalDurationSeconds =>
      phases.fold(0, (sum, p) => sum + p.durationSeconds) * cycles;

  BreathingPattern copyWith({
    String? id,
    String? name,
    String? description,
    List<BreathingPhase>? phases,
    int? cycles,
  }) {
    return BreathingPattern(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      phases: phases ?? this.phases,
      cycles: cycles ?? this.cycles,
    );
  }
}
