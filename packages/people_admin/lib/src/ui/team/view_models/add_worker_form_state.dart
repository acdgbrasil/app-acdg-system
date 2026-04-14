import 'package:flutter/widgets.dart';

/// Mutable form state for the Add Worker modal.
///
/// Holds TextEditingControllers and validation logic for worker registration.
class AddWorkerFormState {
  final fullName = TextEditingController();
  final cpf = TextEditingController();
  final email = TextEditingController();
  final birthDate = TextEditingController();
  final initialPassword = TextEditingController();
  final selectedRole = ValueNotifier<String?>(null);

  String? get fullNameError {
    final text = fullName.text.trim();
    if (text.isEmpty) return 'Campo obrigatorio';
    if (text.length < 3) return 'Minimo 3 caracteres';
    return null;
  }

  String? get emailError {
    final text = email.text.trim();
    if (text.isEmpty) return 'Campo obrigatorio';
    if (!text.contains('@') || !text.contains('.')) return 'E-mail invalido';
    return null;
  }

  String? get birthDateError {
    final text = birthDate.text.trim();
    if (text.isEmpty) return 'Campo obrigatorio';
    if (text.length < 10) return 'Data incompleta';
    return null;
  }

  String? get roleError {
    if (selectedRole.value == null) return 'Selecione um papel';
    return null;
  }

  bool get isValid =>
      fullNameError == null &&
      emailError == null &&
      birthDateError == null &&
      roleError == null;

  void dispose() {
    fullName.dispose();
    cpf.dispose();
    email.dispose();
    birthDate.dispose();
    initialPassword.dispose();
    selectedRole.dispose();
  }
}
