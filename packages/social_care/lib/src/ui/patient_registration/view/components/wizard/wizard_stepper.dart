import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'wizard_step_item.dart';

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
              color: lineIdx < currentStep
                  ? AppColors.primary
                  : AppColors.inputLine,
            ),
          );
        }),
      ),
    );
  }
}
