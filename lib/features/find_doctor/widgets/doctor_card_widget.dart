import 'package:flutter/material.dart';
import '../models/nearby_doctor.dart';

const _kTeal = Color(0xFF5BA8A0);
const _kDark = Color(0xFF1A4A4A);

/// Card widget displaying a [NearbyDoctor] in the search results list.
class DoctorCardWidget extends StatelessWidget {
  final NearbyDoctor doctor;
  final VoidCallback? onTap;
  final VoidCallback? onCallTap;

  const DoctorCardWidget({
    super.key,
    required this.doctor,
    this.onTap,
    this.onCallTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: doctor.distanceKm > 0
          ? '${doctor.name}, ${doctor.distanceKm.toStringAsFixed(1)} km away'
          : doctor.name,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name row with type badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              doctor.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _kDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _TypeBadge(type: doctor.type),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Address
                      Text(
                        doctor.address.isNotEmpty
                            ? doctor.address
                            : 'Address not available',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Distance — only shown when we have a real GPS distance
                      if (doctor.distanceKm > 0)
                        Text(
                          '${doctor.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                // Call button
                if (doctor.phone != null)
                  Semantics(
                    label: 'Call ${doctor.name}',
                    child: IconButton(
                      icon: const Icon(Icons.phone_outlined, color: _kTeal),
                      onPressed: onCallTap,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
