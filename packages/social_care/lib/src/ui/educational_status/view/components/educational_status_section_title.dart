import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class EducationalStatusSectionTitle extends StatelessWidget {
  const EducationalStatusSectionTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Satoshi',
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
    );
  }
}
