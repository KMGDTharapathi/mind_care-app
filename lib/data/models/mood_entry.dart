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

  @HiveField(4)
  final int? levelValue;

  MoodEntry({
    required this.id,
    required this.mood,
    this.note,
    required this.timestamp,
    this.levelValue,
  });

  int get level => levelValue ?? _mapMoodTypeToLevel(mood);

  static int _mapMoodTypeToLevel(MoodType m) {
    return switch (m) {
      MoodType.frustrated => 1,
      MoodType.sad => 3,
      MoodType.tired => 4,
      MoodType.anxious => 5,
      MoodType.calm => 7,
      MoodType.happy => 8,
      MoodType.excited => 10,
    };
  }

  static MoodType mapLevelToMoodType(int lvl) {
    if (lvl <= 2) return MoodType.frustrated;
    if (lvl <= 3) return MoodType.sad;
    if (lvl <= 5) return MoodType.tired;
    if (lvl <= 6) return MoodType.anxious;
    if (lvl <= 7) return MoodType.calm;
    if (lvl <= 9) return MoodType.happy;
    return MoodType.excited;
  }
}
