import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialization;
  final String doctorHospital;
  final DateTime dateTime;
  final String sessionType; // 'audio', 'video', 'in_person'
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final String notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AppointmentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialization,
    required this.doctorHospital,
    required this.dateTime,
    this.sessionType = 'audio',
    this.status = 'pending',
    this.notes = '',
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialization': doctorSpecialization,
      'doctorHospital': doctorHospital,
      'dateTime': Timestamp.fromDate(dateTime),
      'sessionType': sessionType,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return AppointmentModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? '',
      doctorId: map['doctorId'] as String? ?? '',
      doctorName: map['doctorName'] as String? ?? '',
      doctorSpecialization: map['doctorSpecialization'] as String? ?? '',
      doctorHospital: map['doctorHospital'] as String? ?? '',
      dateTime: parseTimestamp(map['dateTime']),
      sessionType: map['sessionType'] as String? ?? 'audio',
      status: map['status'] as String? ?? 'pending',
      notes: map['notes'] as String? ?? '',
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseTimestamp(map['updatedAt']) : null,
    );
  }

  AppointmentModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialization,
    String? doctorHospital,
    DateTime? dateTime,
    String? sessionType,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialization: doctorSpecialization ?? this.doctorSpecialization,
      doctorHospital: doctorHospital ?? this.doctorHospital,
      dateTime: dateTime ?? this.dateTime,
      sessionType: sessionType ?? this.sessionType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
