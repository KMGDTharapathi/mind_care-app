import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../data/local/notification_service.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/repositories/firestore/firestore_appointment_repository.dart';
import '../../../main.dart' show appUserName;

const Color _kTeal = Color(0xFF5BA8A0);
const Color _kDark = Color(0xFF1A4A4A);

class BookAppointmentSheet extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String doctorSpecialization;
  final String doctorHospital;
  final String photoUrl;
  final AppStrings? strings;

  const BookAppointmentSheet({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialization,
    required this.doctorHospital,
    this.photoUrl = '',
    this.strings,
  });

  @override
  State<BookAppointmentSheet> createState() => _BookAppointmentSheetState();
}

class _BookAppointmentSheetState extends State<BookAppointmentSheet> {
  final _appointmentRepo = FirestoreAppointmentRepository();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  String _selectedSlot = '10:00 AM';
  String _sessionType = 'audio'; // 'audio', 'video', 'in_person'
  bool _addToCalendar = true;
  bool _isSubmitting = false;

  final List<String> _timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:30 AM',
    '02:00 PM',
    '03:30 PM',
    '05:00 PM',
    '06:30 PM',
  ];

  @override
  void initState() {
    super.initState();
    // Default to tomorrow at 10:00 AM
    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kTeal,
              onPrimary: Colors.white,
              onSurface: _kDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  DateTime _computeAppointmentDateTime() {
    // Parse the slot string like '10:00 AM'
    int hour = 10;
    int minute = 0;
    try {
      final parsed = DateFormat('hh:mm a').parse(_selectedSlot);
      hour = parsed.hour;
      minute = parsed.minute;
    } catch (_) {}

    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );
  }

  Future<void> _confirmBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'anonymous_user';
    final userEmail = user?.email ?? '';
    final userName = appUserName.value ?? user?.displayName ?? 'Anonymous';

    setState(() => _isSubmitting = true);

    try {
      final appointmentDateTime = _computeAppointmentDateTime();

      final appointment = AppointmentModel(
        id: '',
        userId: uid,
        userName: userName,
        userEmail: userEmail,
        doctorId: widget.doctorId,
        doctorName: widget.doctorName,
        doctorSpecialization: widget.doctorSpecialization,
        doctorHospital: widget.doctorHospital,
        dateTime: appointmentDateTime,
        sessionType: _sessionType,
        status: 'pending',
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      final created = await _appointmentRepo.createAppointment(appointment);

      // Add to calendar if checked
      if (_addToCalendar) {
        try {
          final event = Event(
            title: 'Consultation: ${widget.doctorName}',
            description:
                'Session Type: ${_formatSessionType(_sessionType)}\nDoctor: ${widget.doctorName}\nLocation: ${widget.doctorHospital}',
            location: widget.doctorHospital,
            startDate: appointmentDateTime,
            endDate: appointmentDateTime.add(const Duration(minutes: 45)),
          );
          await Add2Calendar.addEvent2Cal(event);
          await NotificationService.showEventAddedNotification(
            eventTitle: 'Appointment with ${widget.doctorName}',
            provider: 'Calendar',
          );
        } catch (_) {}
      }

      if (!mounted) return;
      Navigator.of(context).pop(created);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Appointment booked for ${DateFormat('MMM dd, yyyy').format(appointmentDateTime)} at $_selectedSlot!'),
              ),
            ],
          ),
          backgroundColor: _kTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book appointment: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  String _formatSessionType(String type) {
    switch (type) {
      case 'video':
        return 'Video Call';
      case 'in_person':
        return 'In-person Visit';
      case 'audio':
      default:
        return 'Audio Call';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings ?? LanguageProvider.of(context);
    final isSinhala = s.isSinhala;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header with Doctor Preview
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _kTeal.withValues(alpha: 0.15),
                  backgroundImage: widget.photoUrl.isNotEmpty
                      ? NetworkImage(widget.photoUrl)
                      : null,
                  child: widget.photoUrl.isEmpty
                      ? const Icon(Icons.person, color: _kTeal, size: 28)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSinhala ? 'වෙන්කිරීම තහවුරු කරන්න' : 'Book Consultation',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _kDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.doctorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${widget.doctorSpecialization} • ${widget.doctorHospital}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),

            // ── 1. Select Date ────────────────────────────────────────────────
            Text(
              isSinhala ? 'දිනය තෝරන්න' : 'Select Date',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kDark,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _DateChip(
                  label: isSinhala ? 'හෙට' : 'Tomorrow',
                  date: DateTime.now().add(const Duration(days: 1)),
                  isSelected: _isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 1))),
                  onTap: () => setState(() => _selectedDate = DateTime.now().add(const Duration(days: 1))),
                ),
                const SizedBox(width: 8),
                _DateChip(
                  label: isSinhala ? 'අනිද්දා' : 'In 2 Days',
                  date: DateTime.now().add(const Duration(days: 2)),
                  isSelected: _isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 2))),
                  onTap: () => setState(() => _selectedDate = DateTime.now().add(const Duration(days: 2))),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month, size: 16, color: _kTeal),
                  label: Text(
                    DateFormat('MMM d').format(_selectedDate),
                    style: const TextStyle(fontSize: 13, color: _kTeal, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _kTeal, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: _pickCustomDate,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 2. Select Time Slot ───────────────────────────────────────────
            Text(
              isSinhala ? 'වේලාව තෝරන්න' : 'Available Time Slots',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kDark,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((slot) {
                final isSelected = _selectedSlot == slot;
                return ChoiceChip(
                  label: Text(slot),
                  selected: isSelected,
                  selectedColor: _kTeal,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (val) {
                    if (val) setState(() => _selectedSlot = slot);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── 3. Session Type ───────────────────────────────────────────────
            Text(
              isSinhala ? 'සැසි ආකාරය' : 'Session Type',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kDark,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SessionTypeCard(
                    icon: Icons.phone_in_talk_rounded,
                    title: isSinhala ? 'ශ්‍රව්‍ය ඇමතුම' : 'Audio Call',
                    isSelected: _sessionType == 'audio',
                    onTap: () => setState(() => _sessionType = 'audio'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SessionTypeCard(
                    icon: Icons.videocam_rounded,
                    title: isSinhala ? 'වීඩියෝ ඇමතුම' : 'Video Call',
                    isSelected: _sessionType == 'video',
                    onTap: () => setState(() => _sessionType = 'video'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SessionTypeCard(
                    icon: Icons.local_hospital_rounded,
                    title: isSinhala ? 'සායනයට පැමිණීම' : 'In-Person',
                    isSelected: _sessionType == 'in_person',
                    onTap: () => setState(() => _sessionType = 'in_person'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 4. Notes ──────────────────────────────────────────────────────
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: isSinhala ? 'විස්තර / සටහන් (විකල්ප)' : 'Notes or concerns (optional)',
                hintText: isSinhala ? 'ඔබ කතා කිරීමට බලාපොරොත්තු වන කරුණු...' : 'Briefly describe what you would like to discuss...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kTeal, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Add to device calendar toggle
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                isSinhala ? 'මගේ දින දර්ශනයට එකතු කරන්න' : 'Add to device calendar',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              activeColor: _kTeal,
              value: _addToCalendar,
              onChanged: (val) => setState(() => _addToCalendar = val ?? true),
            ),
            const SizedBox(height: 16),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
                onPressed: _isSubmitting ? null : _confirmBooking,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        isSinhala ? 'වෙන්කිරීම තහවුරු කරන්න' : 'Confirm Appointment',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kTeal : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _kTeal : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              DateFormat('d MMM').format(date),
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SessionTypeCard({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? _kTeal.withValues(alpha: 0.12) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _kTeal : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isSelected ? _kTeal : Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? _kDark : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
