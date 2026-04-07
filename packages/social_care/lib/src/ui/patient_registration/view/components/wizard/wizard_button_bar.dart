import 'package:flutter/material.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'wizard_button.dart';
import 'wizard_success_button.dart';

class WizardButtonBar extends StatelessWidget {
  final int currentStep;
  final bool isLastStep;
  final bool isNextEnabled;
  final bool isSuccess;
  final double padding;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  const WizardButtonBar({
    super.key,
    required this.currentStep,
    required this.isLastStep,
    required this.isNextEnabled,
    required this.padding,
    this.isSuccess = false,
    this.onBack,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(padding, 24, padding, 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentStep > 0)
            WizardButton(
              label: ReferencePersonLn10.btnBack,
              icon: Icons.arrow_back,
              isPrimary: false,
              onPressed: onBack,
            )
          else
            const SizedBox.shrink(),
          if (isSuccess)
            const WizardSuccessButton()
          else
            WizardButton(
              label: isLastStep
                  ? ReferencePersonLn10.btnSave
                  : ReferencePersonLn10.btnNext,
              icon: isLastStep ? Icons.check : Icons.arrow_forward,
              isPrimary: true,
              onPressed: isNextEnabled ? onNext : null,
            ),
        ],
      ),
    );
  }
}
