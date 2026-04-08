import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/patient_registration_providers.dart';
import '../../viewModel/patient_registration_view_model.dart';
import '../components/registration_error_modal.dart';
import '../components/registration_step_switcher.dart';
import '../components/registration_toast.dart';
import '../components/registration_wizard_template.dart';

class PatientRegistrationPage extends ConsumerStatefulWidget {
  const PatientRegistrationPage({super.key});

  @override
  ConsumerState<PatientRegistrationPage> createState() =>
      _PatientRegistrationPageState();
}

class _PatientRegistrationPageState
    extends ConsumerState<PatientRegistrationPage> {
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(patientRegistrationViewModelProvider);

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return RegistrationWizardTemplate(
          currentStep: vm.currentStep,
          isLastStep: vm.isLastStep,
          isNextEnabled: !_isSuccess,
          isSuccess: _isSuccess,
          onBack: vm.currentStep > 0 && !_isSuccess ? vm.previousStep : null,
          onNext: _isSuccess
              ? null
              : () {
                  if (vm.isLastStep) {
                    _handleSubmit(vm);
                  } else {
                    _handleNext(vm);
                  }
                },
          child: RegistrationStepSwitcher(
            viewModel: vm,
            currentStep: vm.currentStep,
            showErrors: vm.showStepErrors,
          ),
        );
      },
    );
  }

  void _handleNext(PatientRegistrationViewModel vm) {
    final result = vm.handleNext();
    if (result == StepNavigationResult.validationFailed) {
      RegistrationToast.show(
        context,
        message: 'Corrija os campos obrigatórios para continuar',
      );
    }
  }

  Future<void> _handleSubmit(PatientRegistrationViewModel vm) async {
    final result = await vm.handleSubmit();
    if (!mounted) return;

    switch (result) {
      case SubmitResult.success:
        setState(() => _isSuccess = true);
        RegistrationToast.show(
          context,
          message: 'Cadastro salvo com sucesso!',
          type: ToastType.success,
          onDismissed: () {
            if (mounted) context.go('/social-care');
          },
        );
      case SubmitResult.validationFailed:
        RegistrationToast.show(
          context,
          message: 'Corrija os campos obrigatórios para continuar',
        );
      case SubmitResult.networkError:
        _showErrorModal(vm, RegistrationErrorType.network);
      case SubmitResult.domainError:
        RegistrationToast.show(
          context,
          message: vm.errorMessage ?? 'Verifique os dados e tente novamente.',
        );
      case SubmitResult.serverError:
        _showErrorModal(vm, RegistrationErrorType.server);
    }
  }

  void _showErrorModal(
    PatientRegistrationViewModel vm,
    RegistrationErrorType type,
  ) {
    final errorMsg = vm.errorMessage ?? 'Erro desconhecido';
    RegistrationErrorModal.show(
      context,
      type: type,
      errorCode: errorMsg.length > 80 ? errorMsg.substring(0, 80) : errorMsg,
      onRetry: () {
        Navigator.of(context).pop();
        _handleSubmit(vm);
      },
      onClose: () => Navigator.of(context).pop(),
    );
  }
}
