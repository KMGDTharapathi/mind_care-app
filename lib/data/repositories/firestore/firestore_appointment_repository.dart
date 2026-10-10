import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/appointment_model.dart';

/// Repository for managing Doctor & Counsellor appointments in Cloud Firestore.
class FirestoreAppointmentRepository {
  FirestoreAppointmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _userAppointmentsCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('appointments');

  CollectionReference<Map<String, dynamic>> get _globalAppointmentsCol =>
      _firestore.collection('appointments');

  /// Creates a new appointment under the user's subcollection and global appointments.
  Future<AppointmentModel> createAppointment(AppointmentModel appointment) async {
    final userRef = _userAppointmentsCol(appointment.userId).doc();
    final appointmentId = appointment.id.isNotEmpty ? appointment.id : userRef.id;
    final finalAppointment = appointment.copyWith(id: appointmentId);

    final data = finalAppointment.toMap();

    // 1. Write to user's appointments subcollection
    await _userAppointmentsCol(appointment.userId).doc(appointmentId).set(data);

    // 2. Best-effort mirror to global collection for counsellors/doctors
    try {
      await _globalAppointmentsCol.doc(appointmentId).set(data);
    } catch (_) {}

    return finalAppointment;
  }

  /// Real-time stream of all appointments for the specified user.
  Stream<List<AppointmentModel>> streamUserAppointments(String userId) {
    return _userAppointmentsCol(userId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Cancels an existing appointment.
  Future<void> cancelAppointment(String userId, String appointmentId) async {
    final updates = {
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _userAppointmentsCol(userId).doc(appointmentId).update(updates);

    try {
      await _globalAppointmentsCol.doc(appointmentId).update(updates);
    } catch (_) {}
  }

  /// Reschedules an appointment to a new date and time.
  Future<void> rescheduleAppointment(
    String userId,
    String appointmentId,
    DateTime newDateTime,
  ) async {
    final updates = {
      'dateTime': Timestamp.fromDate(newDateTime),
      'status': 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _userAppointmentsCol(userId).doc(appointmentId).update(updates);

    try {
      await _globalAppointmentsCol.doc(appointmentId).update(updates);
    } catch (_) {}
  }
}
