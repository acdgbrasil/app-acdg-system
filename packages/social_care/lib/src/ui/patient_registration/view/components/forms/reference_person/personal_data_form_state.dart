import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:social_care/src/constants/reference_person_ln10.dart';
import 'package:social_care/src/ui/patient_registration/models/enums/gender.dart';
import 'package:social_care/src/ui/patient_registration/models/enums/nationality.dart';
import 'package:social_care/src/ui/patient_registration/models/personal_data.dart';

class PersonalDataFormState {
  static final RegExp _brazilPhoneRegex = RegExp(
    r'^(55)?(?:([1-9]{2})?)(\d{4,5})(\d{4})$',
  );

  // 1. Estados Reativos (Selections)
  final nationality = ValueNotifier<Nationality?>(null);
  final gender = ValueNotifier<Gender?>(null);

  // 2. Controladores para Texto
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final socialName = TextEditingController();
  final motherName = TextEditingController();
  final phoneNumber = TextEditingController();

  final phoneMaskFormatter = PhoneMask();

  // 3. Validadores Reutilizáveis
  String? _namesValidator(String? value, {bool isOptional = false}) {
    if (value == null || value.trim().isEmpty) {
      return isOptional ? null : ReferencePersonLn10.errorRequired;
    }
    if (value.length < 3) return ReferencePersonLn10.errorMinChars3;
    if (RegExp(r'[0-9]').hasMatch(value)) {
      return ReferencePersonLn10.errorNameNoDigits;
    }
    if (RegExp(
      r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:"\\|,.<>\/?]',
    ).hasMatch(value)) {
      return ReferencePersonLn10.errorNameNoSpecialChars;
    }
    return null;
  }

  // Getters de Erro (Para uso em lógica customizada ou UI)
  String? get firstNameError => _namesValidator(firstName.text);
  String? get lastNameError => _namesValidator(lastName.text);
  String? get motherNameError => _namesValidator(motherName.text);
  String? get socialNameError =>
      _namesValidator(socialName.text, isOptional: true);

  String? get phoneNumberError {
    final digitsOnly = phoneNumber.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return null;
    if (!_brazilPhoneRegex.hasMatch(digitsOnly)) {
      return ReferencePersonLn10.errorPhoneInvalid;
    }
    return null;
  }

  // Funções de Validação (Para o Form e os Widgets)
  String? Function(String?) get firstNameValidator => _namesValidator;
  String? Function(String?) get lastNameValidator => _namesValidator;
  String? Function(String?) get motherNameValidator => _namesValidator;
  String? Function(String?) get socialNameValidator =>
      (value) => _namesValidator(value, isOptional: true);

  String? Function(Nationality?) get nationalityValidator =>
      (value) =>
          value == null ? ReferencePersonLn10.errorSelectNationality : null;
  String? Function(Gender?) get genderValidator =>
      (value) => value == null ? ReferencePersonLn10.errorSelectGender : null;

  String? Function(String?) get phoneNumberValidator => (value) {
    final digitsOnly = value?.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly == null || digitsOnly.isEmpty) return null;
    if (!_brazilPhoneRegex.hasMatch(digitsOnly)) {
      return ReferencePersonLn10.errorPhoneInvalid;
    }
    return null;
  };

  // 4. Transformação em Modelo de Dados
  PersonalData toPersonalData() {
    return PersonalData(
      firstName: firstName.text.trim(),
      lastName: lastName.text.trim(),
      socialName: socialName.text.trim().isEmpty
          ? null
          : socialName.text.trim(),
      motherName: motherName.text.trim(),
      nationality: nationality.value ?? Nationality.brasileira,
      sex: gender.value ?? Gender.feminino,
      phone: phoneNumber.text.trim().isEmpty ? null : phoneNumber.text.trim(),
    );
  }

  // 5. Verificação de Status do Step
  bool get isValidForNextStep {
    return firstNameError == null &&
        lastNameError == null &&
        motherNameError == null &&
        socialNameError == null &&
        phoneNumberError == null &&
        nationality.value != null &&
        gender.value != null;
  }

  List<String> get validationErrors => [
    ?firstNameError,
    ?lastNameError,
    ?motherNameError,
    ?socialNameError,
    if (nationality.value == null) ReferencePersonLn10.errorSelectNationality,
    if (gender.value == null) ReferencePersonLn10.errorSelectGender,
    ?phoneNumberError,
  ];

  // 6. Gerenciamento de Memória
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    socialName.dispose();
    motherName.dispose();
    phoneNumber.dispose();
    nationality.dispose();
    gender.dispose();
  }
}
