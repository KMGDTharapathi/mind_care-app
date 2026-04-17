import 'package:hive/hive.dart';

part 'resource.g.dart';

@HiveType(typeId: 3)
class Resource extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final List<String> keywords;

  @HiveField(5)
  bool isBookmarked;

  Resource({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.keywords,
    this.isBookmarked = false,
  });
}
