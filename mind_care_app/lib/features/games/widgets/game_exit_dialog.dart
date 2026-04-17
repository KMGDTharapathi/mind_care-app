import 'package:flutter/material.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';

/// Shows a cute exit confirmation dialog.
/// Returns true if user wants to leave, false to stay.
Future<bool> showGameExitDialog(BuildContext context) async {
  final s = LanguageProvider.of(context);
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cute emoji
            const Text('🎮', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            // Title
            Text(
              s.exitGameTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A4A4A),
              ),
            ),
            const SizedBox(height: 10),
            // Message
            Text(
              s.exitGameMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5A7A7A),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // No button (stay) — primary
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5BA8A0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(s.exitGameNo,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            // Yes button (leave) — secondary
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                  side: BorderSide(color: Colors.red.shade200, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(s.exitGameYes,
                    style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
