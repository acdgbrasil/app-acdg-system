import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class HealthEmptyState extends StatelessWidget {
  const HealthEmptyState({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 14,
          color: AppColors.textPrimary.withValues(alpha: 0.5),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
