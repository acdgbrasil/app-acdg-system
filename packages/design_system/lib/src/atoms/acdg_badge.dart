import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';

/// A small colored pill badge used for inline labels (e.g. table rows).
class AcdgBadge extends StatelessWidget {
  final String label;
  final Color color;

  const AcdgBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Satoshi',
          fontWeight: FontWeight.w700,
          fontSize: 8,
          letterSpacing: 0.8,
          color: AppColors.background,
        ),
      ),
    );
  }
}
