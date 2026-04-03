import 'package:flutter/material.dart';

import '../../viewModel/patient_registration_view_model.dart';
import 'forms/reference_person/step_address_content.dart';
import 'forms/reference_person/step_diagnoses_content.dart';
import 'forms/reference_person/step_documents_content.dart';
import 'forms/reference_person/step_family_composition_content.dart';
import 'forms/reference_person/step_intake_info_content.dart';
import 'forms/reference_person/step_personal_data_content.dart';
import 'forms/reference_person/step_specificities_content.dart';

/// Stateless widget that returns the correct step content based on [currentStep].
class RegistrationStepSwitcher extends StatelessWidget {
  const RegistrationStepSwitcher({
    super.key,
    required this.viewModel,
    required this.currentStep,
    required this.showErrors,
  });

  final PatientRegistrationViewModel viewModel;
  final int currentStep;
  final bool showErrors;

  @override
  Widget build(BuildContext context) {
    return switch (currentStep) {
      0 => StepPersonalDataContent(
          formState: viewModel.referencePersonFormState,
          showErrors: showErrors,
        ),
      1 => StepDocumentsContent(
          formState: viewModel.documentsFormState,
          showErrors: showErrors,
        ),
      2 => StepAddressContent(
          formState: viewModel.addressFormState,
          showErrors: showErrors,
        ),
      3 => StepDiagnosesContent(
          formState: viewModel.diagnosesFormState,
          showErrors: showErrors,
        ),
      4 => StepFamilyCompositionContent(
          formState: viewModel.familyCompositionFormState,
          personalDataFormState: viewModel.referencePersonFormState,
          documentsFormState: viewModel.documentsFormState,
          parentescoLookup: viewModel.parentescoLookup,
          showErrors: showErrors,
        ),
      5 => StepSpecificitiesContent(
          formState: viewModel.specificitiesFormState,
          identityTypeLookup: viewModel.identityTypeLookup,
          showErrors: showErrors,
        ),
      6 => StepIntakeInfoContent(
          formState: viewModel.intakeInfoFormState,
          ingressTypeLookup: viewModel.ingressTypeLookup,
          socialProgramsLookup: viewModel.socialProgramsLookup,
          showErrors: showErrors,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
