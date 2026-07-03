import 'package:flutter/material.dart';

const _kTeal = Color(0xFF5BA8A0);

/// Shown when a search completes but returns zero results.
class EmptyView extends StatelessWidget {
  final int radiusKm;

  const EmptyView({super.key, required this.radiusKm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 64,
              color: _kTeal,
            ),
            const SizedBox(height: 16),
            Text(
              'No mental health providers found within $radiusKm km.\nTry increasing the search radius.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
