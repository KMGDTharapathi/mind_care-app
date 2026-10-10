import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../data/local/notification_service.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/repositories/firestore/firestore_appointment_repository.dart';

const Color _kTeal = Color(0xFF5BA8A0);
const Color _kDark = Color(0xFF1A4A4A);

class AppointmentsTab extends StatelessWidget {
  final AppStrings strings;
  final VoidCallback? onFindDoctor;

  const AppointmentsTab({
    super.key,
    required this.strings,
    this.onFindDoctor,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isSinhala = strings.isSinhala;

    if (uid == null || uid.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                isSinhala ? 'කරුණාකර ප්‍රථමයෙන් පුරනය වන්න' : 'Please Sign In',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kDark),
              ),
              const SizedBox(height: 8),
              Text(
                isSinhala
                    ? 'ඔබගේ වෙන්කිරීම් බැලීමට සහ කළමනාකරණය කිරීමට ගිණුමකට පිවිසෙන්න.'
                    : 'Sign in to view and manage your booked appointments.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    final repo = FirestoreAppointmentRepository();

    return StreamBuilder<List<AppointmentModel>>(
      stream: repo.streamUserAppointments(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _kTeal),
          );
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _kTeal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.event_available_outlined, size: 40, color: _kTeal),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isSinhala ? 'වෙන්කිරීම් කිසිවක් නැත' : 'No Appointments Yet',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSinhala
                        ? 'ඔබ වෛද්‍යවරයකු හෝ උපදේශකයකු සමඟ සැසියක් වෙන් කළ පසු, එය මෙහි දැකගත හැකිය.'
                        : 'When you book a session with a psychologist, counsellor, or doctor, it will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.search, size: 18),
                    label: Text(isSinhala ? 'වෛද්‍යවරයකු සොයන්න' : 'Find a Doctor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: onFindDoctor,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: appointments.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final appt = appointments[index];
            return _AppointmentCard(
              appointment: appt,
              isSinhala: isSinhala,
              repo: repo,
              uid: uid,
            );
          },
        );
      },
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isSinhala;
  final FirestoreAppointmentRepository repo;
  final String uid;

  const _AppointmentCard({
    required this.appointment,
    required this.isSinhala,
    required this.repo,
    required this.uid,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red.shade400;
      case 'completed':
        return Colors.blue;
      case 'pending':
      default:
        return Colors.orange.shade700;
    }
  }

  String _statusLabel(String status) {
    if (isSinhala) {
      switch (status.toLowerCase()) {
        case 'confirmed':
          return 'තහවුරු කර ඇත';
        case 'cancelled':
          return 'අවලංගුයි';
        case 'completed':
          return 'සම්පූර්ණයි';
        case 'pending':
        default:
          return 'තහවුරු වෙමින් පවතී';
      }
    }
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  String _sessionTypeLabel(String type) {
    switch (type) {
      case 'video':
        return isSinhala ? '📹 වීඩියෝ ඇමතුම' : '📹 Video Call';
      case 'in_person':
        return isSinhala ? '🏥 සායනයට පැමිණීම' : '🏥 In-Person';
      case 'audio':
      default:
        return isSinhala ? '📞 ශ්‍රව්‍ය ඇමතුම' : '📞 Audio Call';
    }
  }

  Future<void> _cancelAppointment(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isSinhala ? 'වෙන්කිරීම අවලංගු කරන්නද?' : 'Cancel Appointment?'),
        content: Text(
          isSinhala
              ? '${appointment.doctorName} සමඟ ඇති මෙම සැසිය අවලංගු කිරීමට ඔබට සහතිකද?'
              : 'Are you sure you want to cancel your appointment with ${appointment.doctorName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isSinhala ? 'නැත' : 'No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isSinhala ? 'ඔව්, අවලංගු කරන්න' : 'Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await repo.cancelAppointment(uid, appointment.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSinhala ? 'වෙන්කිරීම සාර්ථකව අවලංගු කරන ලදී.' : 'Appointment cancelled successfully.'),
          ),
        );
      }
    }
  }

  Future<void> _addToCalendar(BuildContext context) async {
    try {
      final event = Event(
        title: 'MindCare: ${appointment.doctorName}',
        description: 'Doctor: ${appointment.doctorName}\nType: ${_sessionTypeLabel(appointment.sessionType)}\nHospital: ${appointment.doctorHospital}',
        location: appointment.doctorHospital,
        startDate: appointment.dateTime,
        endDate: appointment.dateTime.add(const Duration(minutes: 45)),
      );
      await Add2Calendar.addEvent2Cal(event);
      await NotificationService.showEventAddedNotification(
        eventTitle: 'Appointment with ${appointment.doctorName}',
        provider: 'Calendar',
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = appointment.status.toLowerCase() == 'cancelled';
    final statusColor = _statusColor(appointment.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Session Type Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        _statusLabel(appointment.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _sessionTypeLabel(appointment.sessionType),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Doctor details
            Text(
              appointment.doctorName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCancelled ? Colors.grey : _kDark,
                decoration: isCancelled ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${appointment.doctorSpecialization} • ${appointment.doctorHospital}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const Divider(height: 20),

            // Date and time row
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 16, color: _kTeal),
                const SizedBox(width: 6),
                Text(
                  DateFormat('EEE, MMM d, yyyy').format(appointment.dateTime),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.access_time_outlined, size: 16, color: _kTeal),
                const SizedBox(width: 6),
                Text(
                  DateFormat('hh:mm a').format(appointment.dateTime),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),

            if (appointment.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appointment.notes,
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                ),
              ),
            ],

            if (!isCancelled) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 14, color: _kTeal),
                    label: Text(isSinhala ? 'දින දර්ශනය' : 'Add to Calendar', style: const TextStyle(fontSize: 12, color: _kTeal)),
                    onPressed: () => _addToCalendar(context),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: Icon(Icons.cancel_outlined, size: 14, color: Colors.red.shade400),
                    label: Text(isSinhala ? 'අවලංගු කරන්න' : 'Cancel', style: TextStyle(fontSize: 12, color: Colors.red.shade400)),
                    onPressed: () => _cancelAppointment(context),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
