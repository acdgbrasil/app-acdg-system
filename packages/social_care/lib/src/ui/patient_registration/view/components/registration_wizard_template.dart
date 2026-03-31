import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'wizard/wizard_button_bar.dart';
import 'wizard/wizard_header.dart';
import 'wizard/wizard_nav_bar.dart';
import 'wizard/wizard_stepper.dart';

class RegistrationWizardTemplate extends StatelessWidget {
  final int currentStep;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final bool isLastStep;
  final bool isNextEnabled;
  final bool isSuccess;

  const RegistrationWizardTemplate({
    super.key,
    required this.currentStep,
    required this.child,
    this.onBack,
    this.onNext,
    this.isLastStep = false,
    this.isNextEnabled = true,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = AppBreakpoints.isMobile(screenWidth);
    final horizontalPadding = isMobile ? 20.0 : 48.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WizardNavBar(padding: horizontalPadding),
            WizardHeader(padding: horizontalPadding),
            WizardStepper(
              currentStep: currentStep,
              padding: horizontalPadding,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: child,
              ),
            ),
            WizardButtonBar(
              currentStep: currentStep,
              isLastStep: isLastStep,
              isNextEnabled: isNextEnabled,
              isSuccess: isSuccess,
              padding: horizontalPadding,
              onBack: onBack,
              onNext: onNext,
            ),
          ],
        ),
      ),
    );
  }
}
