import 'package:flutter/material.dart';

const _kTeal = Color(0xFF5BA8A0);

/// Search bar with a text field for district input and a GPS icon button.
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onGpsTap;
  final ValueChanged<String> onSubmitted;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onGpsTap,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search by district (e.g. Colombo)',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kTeal),
          ),
          suffixIcon: SizedBox(
            width: 48,
            height: 48,
            child: Semantics(
              label: 'Use current location',
              child: IconButton(
                icon: const Icon(Icons.my_location_rounded, color: _kTeal),
                onPressed: onGpsTap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
