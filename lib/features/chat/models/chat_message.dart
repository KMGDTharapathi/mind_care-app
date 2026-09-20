import 'package:hive/hive.dart';

part 'chat_message.g.dart';

enum MessageSender { user, willow }
enum MessageType { text, voice, image, file }

@HiveType(typeId: 20)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String senderName; // 'user' or 'willow'

  @HiveField(2)
  final String typeName; // 'text', 'voice', 'image', 'file'

  @HiveField(3)
  final String content; // text content or file path

  @HiveField(4)
  final String? fileName; // for file messages

  @HiveField(5)
  final int durationSeconds; // for voice messages

  @HiveField(6)
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.typeName,
    required this.content,
    this.fileName,
    this.durationSeconds = 0,
    required this.timestamp,
  });

  MessageSender get sender =>
      senderName == 'user' ? MessageSender.user : MessageSender.willow;

  MessageType get type {
    switch (typeName) {
      case 'voice': return MessageType.voice;
      case 'image': return MessageType.image;
      case 'file': return MessageType.file;
      default: return MessageType.text;
    }
  }

  factory ChatMessage.text({
    required String id,
    required MessageSender sender,
    required String text,
    required DateTime timestamp,
  }) => ChatMessage(
    id: id,
    senderName: sender == MessageSender.user ? 'user' : 'willow',
    typeName: 'text',
    content: text,
    timestamp: timestamp,
  );

  factory ChatMessage.voice({
    required String id,
    required String filePath,
    required int durationSeconds,
    required DateTime timestamp,
  }) => ChatMessage(
    id: id,
    senderName: 'user',
    typeName: 'voice',
    content: filePath,
    durationSeconds: durationSeconds,
    timestamp: timestamp,
  );

  factory ChatMessage.image({
    required String id,
    required String filePath,
    required DateTime timestamp,
  }) => ChatMessage(
    id: id,
    senderName: 'user',
    typeName: 'image',
    content: filePath,
    timestamp: timestamp,
  );

  factory ChatMessage.file({
    required String id,
    required String filePath,
    required String fileName,
    required DateTime timestamp,
  }) => ChatMessage(
    id: id,
    senderName: 'user',
    typeName: 'file',
    content: filePath,
    fileName: fileName,
    timestamp: timestamp,
  );
}
