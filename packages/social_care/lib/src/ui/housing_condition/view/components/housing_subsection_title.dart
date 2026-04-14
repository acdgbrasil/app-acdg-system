import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class HousingSubsectionTitle extends StatelessWidget {
  const HousingSubsectionTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Satoshi',
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.textPrimary.withValues(alpha: 0.7),
      ),
    );
  }
}
