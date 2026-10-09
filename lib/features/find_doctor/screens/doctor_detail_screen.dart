import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/nearby_doctor.dart';

const _kTeal = Color(0xFF5BA8A0);
const _kDark = Color(0xFF1A4A4A);

class DoctorDetailScreen extends StatelessWidget {
  final NearbyDoctor doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F9),
      appBar: AppBar(
        title: Text(doctor.name),
        backgroundColor: _kTeal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: _kTeal.withOpacity(0.15),
                    child: const Icon(
                      Icons.local_hospital_outlined,
                      color: _kTeal,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    doctor.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: _kDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TypeBadge(type: doctor.type),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Distance row ─────────────────────────────────────────────
            _infoRow(
              Icons.place_outlined,
              '${doctor.distanceKm.toStringAsFixed(1)} km away',
              Colors.grey.shade600,
            ),

            // ── Address section ──────────────────────────────────────────
            if (doctor.address.isNotEmpty) ...[
              _sectionTitle('Address'),
              _infoRow(
                Icons.location_on_outlined,
                doctor.address,
                _kTeal,
                onTap: () async {
                  final uri = Uri.parse(
                    'https://maps.google.com/?q=${Uri.encodeComponent(doctor.address)}',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],

            // ── Phone section ────────────────────────────────────────────
            if (doctor.phone != null) ...[
              _sectionTitle('Phone'),
              Semantics(
                label: 'Call ${doctor.phone}',
                child: _infoRow(
                  Icons.phone_outlined,
                  doctor.phone!,
                  _kTeal,
                  onTap: () async {
                    final uri = Uri(scheme: 'tel', path: doctor.phone);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
              ),
            ],

            // ── Website section ──────────────────────────────────────────
            if (doctor.website != null) ...[
              _sectionTitle('Website'),
              Semantics(
                label: 'Open website',
                child: _infoRow(
                  Icons.language_outlined,
                  doctor.website!,
                  _kTeal,
                  onTap: () async {
                    final uri = Uri.parse(doctor.website!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Get Directions button ────────────────────────────────────
            Semantics(
              label: 'Get directions to ${doctor.name}',
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('Get Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _getDirections(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getDirections(BuildContext context) async {
    final uri = Uri.parse(
      'geo:${doctor.lat},${doctor.lng}?q=${doctor.lat},${doctor.lng}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No maps application found on this device.'),
          ),
        );
      }
    }
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _infoRow(
    IconData icon,
    String text,
    Color iconColor, {
    VoidCallback? onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    color: onTap != null ? iconColor : Colors.black87,
                    decoration:
                        onTap != null ? TextDecoration.underline : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Type badge (mirrors _TypeBadge in doctor_card_widget.dart) ────────────────

class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _kTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        type,
        style: const TextStyle(
          fontSize: 11,
          color: _kTeal,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
