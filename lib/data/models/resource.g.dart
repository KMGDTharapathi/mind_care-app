// GENERATED CODE - DO NOT MODIFY BY HAND
// Manually written Hive TypeAdapters (replaces build_runner output)

part of 'resource.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ResourceAdapter extends TypeAdapter<Resource> {
  @override
  final int typeId = 3;

  @override
  Resource read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Resource(
      id: fields[0] as String,
      title: fields[1] as String,
      category: fields[2] as String,
      content: fields[3] as String,
      keywords: (fields[4] as List).cast<String>(),
      isBookmarked: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Resource obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.keywords)
      ..writeByte(5)
      ..write(obj.isBookmarked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
