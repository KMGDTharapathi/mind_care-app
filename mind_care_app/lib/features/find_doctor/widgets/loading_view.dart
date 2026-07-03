import 'package:flutter/material.dart';

const _kTeal = Color(0xFF5BA8A0);

/// Centred loading indicator shown while an async operation is in progress.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _kTeal),
    );
  }
}
