import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

const _kTeal = Color(0xFF5BA8A0);

/// Shown when location permission has been denied.
///
/// If [isPermanent] is `true`, the user must open Settings to re-enable
/// location access. Otherwise, a prompt to use district search is shown.
class PermissionDeniedView extends StatelessWidget {
  final bool isPermanent;

  const PermissionDeniedView({
    super.key,
    required this.isPermanent,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermanent ? Icons.location_off_rounded : Icons.location_disabled_rounded,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isPermanent
                  ? 'Location access blocked. Enable it in Settings, or use district search.'
                  : 'Location access denied. Use district search below.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
            if (isPermanent) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Geolocator.openAppSettings(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Open Settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
