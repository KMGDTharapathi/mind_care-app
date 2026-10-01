import 'package:cloud_firestore/cloud_firestore.dart';

class WellnessSessionModel {
  final String id;
  final String userId;
  final String type; // 'meditation', 'breathing', 'music', 'coloring'
  final String title;
  final int durationSeconds;
  final DateTime completedAt;
  final Map<String, dynamic> metadata;

  const WellnessSessionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.durationSeconds,
    required this.completedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'durationSeconds': durationSeconds,
      'completedAt': Timestamp.fromDate(completedAt),
      'metadata': metadata,
    };
  }

  factory WellnessSessionModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return WellnessSessionModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? 'general',
      title: map['title'] as String? ?? '',
      durationSeconds: map['durationSeconds'] as int? ?? 0,
      completedAt: parseTimestamp(map['completedAt']),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
    );
  }
}
