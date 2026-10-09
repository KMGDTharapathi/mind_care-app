import 'package:hive/hive.dart';

part 'mood_entry.g.dart';

@HiveType(typeId: 0)
enum MoodType {
  @HiveField(0)
  happy,
  @HiveField(1)
  sad,
  @HiveField(2)
  anxious,
  @HiveField(3)
  frustrated,
  @HiveField(4)
  calm,
  @HiveField(5)
  excited,
  @HiveField(6)
  tired,
}

@HiveType(typeId: 1)
class MoodEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final MoodType mood;

  @HiveField(2)
  final String? note;

  @HiveField(3)
  final DateTime timestamp;

  MoodEntry({
    required this.id,
    required this.mood,
    this.note,
    required this.timestamp,
  });
}
