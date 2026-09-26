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

  BreathingPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.phases,
  });
}
