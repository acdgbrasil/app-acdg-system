import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/step_address_content.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/step_diagnoses_content.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/step_documents_content.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/step_family_composition_content.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/step_intake_info_content.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/step_personal_data_content.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/step_specificities_content.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_error_modal.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_toast.dart';
import 'package:social_care/src/ui/patient_registration/view/components/registration_wizard_template.dart';
import 'package:social_care/src/ui/patient_registration/viewModel/patient_registration_view_model.dart';

class PatientRegistrationPage extends StatefulWidget {
  const PatientRegistrationPage({super.key});

  @override
  State<PatientRegistrationPage> createState() => _PatientRegistrationPageState();
}

class _PatientRegistrationPageState extends State<PatientRegistrationPage> {
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<PatientRegistrationViewModel>();

    return ListenableBuilder(
      listenable: Listenable.merge([viewModel.currentStep, viewModel.showStepErrors]),
      builder: (context, _) {
        final step = viewModel.currentStep.value;
        final showErrors = viewModel.showStepErrors.value;

        return RegistrationWizardTemplate(
          currentStep: step,
          isLastStep: viewModel.isLastStep,
          isNextEnabled: !_isSuccess,
          isSuccess: _isSuccess,
          onBack: step > 0 && !_isSuccess ? viewModel.previousStep : null,
          onNext: _isSuccess ? null : () {
            if (viewModel.isLastStep) {
              _handleSubmit(context, viewModel);
            } else {
              _handleNext(context, viewModel);
            }
          },
          child: _buildStepContent(viewModel, step, showErrors),
        );
      },
    );
  }

  Widget _buildStepContent(PatientRegistrationViewModel viewModel, int step, bool showErrors) {
    return switch (step) {
      0 => StepPersonalDataContent(formState: viewModel.referencePersonFormState, showErrors: showErrors),
      1 => StepDocumentsContent(formState: viewModel.documentsFormState, showErrors: showErrors),
      2 => StepAddressContent(formState: viewModel.addressFormState, showErrors: showErrors),
      3 => StepDiagnosesContent(formState: viewModel.diagnosesFormState, showErrors: showErrors),
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

  void _handleNext(BuildContext context, PatientRegistrationViewModel viewModel) {
    if (viewModel.validateCurrentStep()) {
      viewModel.nextStep();
    } else {
      viewModel.showStepErrors.value = true;
      viewModel.notifyListeners();

      RegistrationToast.show(
        context,
        message: 'Corrija os campos obrigatórios para continuar',
        type: ToastType.error,
      );
    }
  }

  Future<void> _handleSubmit(BuildContext context, PatientRegistrationViewModel viewModel) async {
    if (!viewModel.validateCurrentStep()) {
      viewModel.showStepErrors.value = true;
      viewModel.notifyListeners();

      RegistrationToast.show(
        context,
        message: 'Corrija os campos obrigatórios para continuar',
        type: ToastType.error,
      );
      return;
    }

    await viewModel.registerPatient();
    if (!context.mounted) return;

    final command = viewModel.registerPatientCommand;

    if (command.completed) {
      setState(() => _isSuccess = true);

      RegistrationToast.show(
        context,
        message: 'Cadastro salvo com sucesso!',
        type: ToastType.success,
        onDismissed: () {
          if (context.mounted) context.go('/social-care');
        },
      );
    } else if (command.error) {
      final errorMsg = viewModel.errorMessage ?? 'Erro desconhecido';
      final isNetwork = errorMsg.contains('SocketException') ||
          errorMsg.contains('TimeoutException') ||
          errorMsg.contains('network');

      RegistrationErrorModal.show(
        context,
        type: isNetwork
            ? RegistrationErrorType.network
            : RegistrationErrorType.server,
        errorCode: errorMsg.length > 80 ? errorMsg.substring(0, 80) : errorMsg,
        onRetry: () {
          Navigator.of(context).pop();
          _handleSubmit(context, viewModel);
        },
        onClose: () => Navigator.of(context).pop(),
      );
    }
  }
}
