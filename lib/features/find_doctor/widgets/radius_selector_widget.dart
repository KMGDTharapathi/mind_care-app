import 'package:flutter/material.dart';

const _kTeal = Color(0xFF5BA8A0);

/// Horizontal scrollable row of radius choice chips (5, 10, 20, 50 km).
class RadiusSelectorWidget extends StatelessWidget {
  final int selectedRadius;
  final ValueChanged<int> onRadiusChanged;

  static const _radii = [5, 10, 20, 50];

  const RadiusSelectorWidget({
    super.key,
    required this.selectedRadius,
    required this.onRadiusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: _radii.map((radius) {
          final isSelected = radius == selectedRadius;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              label: '$radius km radius',
              child: ChoiceChip(
                label: Text('$radius km'),
                selected: isSelected,
                onSelected: (_) => onRadiusChanged(radius),
                backgroundColor: Colors.white,
                selectedColor: _kTeal,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: isSelected ? _kTeal : Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
