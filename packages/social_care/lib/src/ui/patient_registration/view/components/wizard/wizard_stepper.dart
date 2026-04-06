import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';

class WizardStepper extends StatelessWidget {
  final int currentStep;
  final double padding;

  const WizardStepper({
    super.key,
    required this.currentStep,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      ReferencePersonLn10.stepPersonalData,
      ReferencePersonLn10.stepDocuments,
      ReferencePersonLn10.stepAddress,
      ReferencePersonLn10.stepDiagnoses,
      ReferencePersonLn10.stepFamilyComposition,
      ReferencePersonLn10.stepSpecificities,
      ReferencePersonLn10.stepIntakeInfo,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 0, padding, 32),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isEven) {
            final stepIdx = index ~/ 2;
            return WizardStepItem(
              number: stepIdx + 1,
              label: steps[stepIdx],
              isActive: stepIdx == currentStep,
              isCompleted: stepIdx < currentStep,
            );
          }
          final lineIdx = index ~/ 2;
          return Expanded(
            child: Container(
              height: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: lineIdx < currentStep ? AppColors.primary : AppColors.inputLine,
            ),
          );
        }),
      ),
    );
  }
}

class WizardStepItem extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isCompleted;

  const WizardStepItem({
    super.key,
    required this.number,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = AppBreakpoints.isMobile(screenWidth);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.primary
                : (isActive ? AppColors.textPrimary : Colors.transparent),
            border: Border.all(
              color: isCompleted
                  ? AppColors.primary
                  : (isActive ? AppColors.textPrimary : AppColors.inputLine),
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: AppColors.background)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isActive ? AppColors.background : AppColors.textMuted,
                    ),
                  ),
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}
