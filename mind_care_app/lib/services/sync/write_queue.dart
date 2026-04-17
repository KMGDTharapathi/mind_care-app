import 'package:hive/hive.dart';

// WriteOperation enum with manual TypeAdapter (typeId: 11)
enum WriteOperation { upsert, delete }

class WriteOperationAdapter extends TypeAdapter<WriteOperation> {
  @override
  final int typeId = 11;

  @override
  WriteOperation read(BinaryReader reader) {
    final index = reader.readByte();
    return WriteOperation.values[index];
  }

  @override
  void write(BinaryWriter writer, WriteOperation obj) {
    writer.writeByte(obj.index);
  }
}

// WriteQueueEntry with manual TypeAdapter (typeId: 10)
class WriteQueueEntry {
  final String id;
  final String collection;
  final String documentId;
  final Map<String, dynamic> data;
  final WriteOperation operation;
  final DateTime enqueuedAt;

  WriteQueueEntry({
    required this.id,
    required this.collection,
    required this.documentId,
    required this.data,
    required this.operation,
    required this.enqueuedAt,
  });
}

class WriteQueueEntryAdapter extends TypeAdapter<WriteQueueEntry> {
  @override
  final int typeId = 10;

  @override
  WriteQueueEntry read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return WriteQueueEntry(
      id: fields[0] as String,
      collection: fields[1] as String,
      documentId: fields[2] as String,
      data: (fields[3] as Map).cast<String, dynamic>(),
      operation: fields[4] as WriteOperation,
      enqueuedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WriteQueueEntry obj) {
    writer.writeByte(6); // number of fields
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.collection);
    writer.writeByte(2);
    writer.write(obj.documentId);
    writer.writeByte(3);
    writer.write(obj.data);
    writer.writeByte(4);
    writer.write(obj.operation);
    writer.writeByte(5);
    writer.write(obj.enqueuedAt);
  }
}

// WriteQueue manages a Hive Box<WriteQueueEntry>
class WriteQueue {
  static const String _boxName = 'write_queue';

  final Box<WriteQueueEntry> _box;

  WriteQueue._(this._box);

  /// Creates a [WriteQueue] from an already-open Hive box.
  /// Use this to avoid opening the same box twice (which can deadlock).
  WriteQueue.fromBox(Box<WriteQueueEntry> box) : _box = box;

  static Future<WriteQueue> open() async {
    final box = await Hive.openBox<WriteQueueEntry>(_boxName);
    return WriteQueue._(box);
  }

  Future<void> enqueue(WriteQueueEntry entry) async {
    await _box.put(entry.id, entry);
  }

  Future<void> dequeue(String id) async {
    await _box.delete(id);
  }

  List<WriteQueueEntry> getAll() {
    final entries = _box.values.toList();
    entries.sort((a, b) => a.enqueuedAt.compareTo(b.enqueuedAt));
    return entries;
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
