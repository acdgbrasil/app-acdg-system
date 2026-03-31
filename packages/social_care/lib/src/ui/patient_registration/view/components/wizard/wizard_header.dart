import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

class WizardHeader extends StatelessWidget {
  final double padding;

  const WizardHeader({super.key, required this.padding});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
      child: Text(
        ReferencePersonLn10.wizardTitle,
        style: AppTypography.displayLarge(screenWidth).copyWith(
          color: AppColors.textPrimary,
          height: 1.1,
        ),
      ),
    );
  }
}
