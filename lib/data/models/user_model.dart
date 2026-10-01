import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile domain model synced with Cloud Firestore (`users/{uid}`).
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phone;
  final String? studentYear;
  final String role;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final String language;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phone,
    this.studentYear,
    this.role = 'student',
    this.createdAt,
    this.lastLoginAt,
    this.language = 'en',
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      phone: data['phone'] as String?,
      studentYear: data['studentYear'] as String?,
      role: data['role'] as String? ?? 'student',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      language: data['language'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (phone != null) 'phone': phone,
      if (studentYear != null) 'studentYear': studentYear,
      'role': role,
      'language': language,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? phone,
    String? studentYear,
    String? language,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      studentYear: studentYear ?? this.studentYear,
      role: role,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      language: language ?? this.language,
    );
  }
}
