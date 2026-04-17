// GENERATED CODE - DO NOT MODIFY BY HAND
// Manually written Hive TypeAdapters (replaces build_runner output)

part of 'breathing_pattern.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BreathingPhaseAdapter extends TypeAdapter<BreathingPhase> {
  @override
  final int typeId = 4;

  @override
  BreathingPhase read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BreathingPhase(
      label: fields[0] as String,
      durationSeconds: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BreathingPhase obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.label)
      ..writeByte(1)
      ..write(obj.durationSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreathingPhaseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BreathingPatternAdapter extends TypeAdapter<BreathingPattern> {
  @override
  final int typeId = 5;

  @override
  BreathingPattern read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BreathingPattern(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      phases: (fields[3] as List).cast<BreathingPhase>(),
    );
  }

  @override
  void write(BinaryWriter writer, BreathingPattern obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.phases);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreathingPatternAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
