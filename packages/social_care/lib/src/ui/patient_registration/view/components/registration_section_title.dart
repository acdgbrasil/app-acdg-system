import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class RegistrationSectionTitle extends StatelessWidget {
  final String title;

  const RegistrationSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTypography.headingSmall(screenWidth).copyWith(
            color: AppColors.textMuted,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(
          color: AppColors.inputLine,
          thickness: 1,
          height: 1,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
