import 'package:flutter/material.dart';

class CrisisAlertBanner extends StatelessWidget {
  const CrisisAlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(bottom: BorderSide(color: Colors.red.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'හදිසි සහාය / Emergency Support',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '📞 සුමිත්‍රයෝ (Sumithrayo): 011-2696666',
            style: TextStyle(fontSize: 13),
          ),
          const Text(
            '📞 මානසික සෞඛ්‍ය උදව් (Mental Health Helpline): 1926',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'ඔබ තනිව නෙමෙයි. කරුණාකර සහාය ලබා ගන්න.',
            style: TextStyle(fontSize: 12, color: Colors.red.shade600),
          ),
        ],
      ),
    );
  }
}
