import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';
import 'package:social_care/src/ui/patient_registration/models/enums/gender.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/address_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/diagnoses_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/documents_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/personal_data_form_state.dart';

class PatientRegistrationViewModel extends BaseViewModel {
  PatientRegistrationViewModel({
    required RegisterPatientUseCase useCase,
    required LookupRepository lookupRepository,
  }) : _lookupRepository = lookupRepository {
    registerPatientCommand = Command1<PatientId, RegisterPatientIntent>(
      (intent) => useCase.execute(intent),
    );
    _loadPrRelationshipId();
  }

  final LookupRepository _lookupRepository;
  late final Command1<PatientId, RegisterPatientIntent> registerPatientCommand;
  String? _prRelationshipId;

  Future<void> _loadPrRelationshipId() async {
    final result = await _lookupRepository.getLookupTable('dominio_parentesco');
    if (result case Success(:final value)) {
      final pessoaRef = value.where((item) => item.codigo == 'PESSOA_REFERENCIA');
      if (pessoaRef.isNotEmpty) {
        _prRelationshipId = pessoaRef.first.id;
      }
    }
  }

  // ── FormsHolds (um por step) ─────────────────────────────────
  final referencePersonFormState = PersonalDataFormState();
  final documentsFormState = DocumentsFormState();
  final addressFormState = AddressFormState();
  final diagnosesFormState = DiagnosesFormState();

  // ── Estado global do wizard ──────────────────────────────────
  final currentStep = ValueNotifier<int>(0);
  final showStepErrors = ValueNotifier<bool>(false);

  bool get isLastStep => currentStep.value == 3;

  List<String> get currentStepErrors => switch (currentStep.value) {
    0 => referencePersonFormState.validationErrors,
    1 => documentsFormState.validationErrors,
    2 => addressFormState.validationErrors,
    3 => diagnosesFormState.validationErrors,
    _ => [],
  };

  // ── Navegação ────────────────────────────────────────────────
  bool validateCurrentStep() {
    return switch (currentStep.value) {
      0 => referencePersonFormState.isValidForNextStep,
      1 => documentsFormState.isValidForNextStep,
      2 => addressFormState.isValidForNextStep,
      3 => diagnosesFormState.isValidForNextStep,
      _ => false,
    };
  }

  void nextStep() {
    if (currentStep.value >= 3) return;
    if (!validateCurrentStep()) {
      showStepErrors.value = true;
      notifyListeners();
      return;
    }
    showStepErrors.value = false;
    currentStep.value = currentStep.value + 1;
  }

  void previousStep() {
    if (currentStep.value <= 0) return;
    showStepErrors.value = false;
    currentStep.value = currentStep.value - 1;
  }

  // ── Build intent final ───────────────────────────────────────
  RegisterPatientIntent buildIntent() {
    final personal = referencePersonFormState;
    final docs = documentsFormState;
    final addr = addressFormState;

    final sex = personal.gender.value == Gender.masculino
        ? Sex.masculino
        : Sex.feminino;

    final residenceLocation = addr.residenceLocation.value == 'urbano'
        ? ResidenceLocation.urbano
        : addr.residenceLocation.value == 'rural'
            ? ResidenceLocation.rural
            : null;

    return RegisterPatientIntent(
      // IDs gerados
      personId: UuidUtil.generateV4(),
      prRelationshipId: _prRelationshipId ?? UuidUtil.generateV4(),

      // Step 0 — Dados Pessoais
      firstName: personal.firstName.text.trim(),
      lastName: personal.lastName.text.trim(),
      motherName: personal.motherName.text.trim(),
      nationality: personal.nationality.value?.name ?? 'brasileira',
      sex: sex,
      socialName: _nullIfEmpty(personal.socialName.text),
      phone: _nullIfEmpty(personal.phoneNumber.text),

      // Step 1 — Documentos & Nascimento
      birthDate: docs.birthDateParsed!,
      cpf: _nullIfEmpty(docs.cpfDigits),
      nis: _nullIfEmpty(docs.nisDigits),
      rgNumber: _nullIfEmpty(docs.rgNumber.text),
      rgAgency: _nullIfEmpty(docs.rgAgency.text),
      rgState: docs.rgUf.value,
      rgDate: docs.rgDateParsed,

      // Step 2 — Endereço
      cep: _nullIfEmpty(addr.cepDigits),
      street: _nullIfEmpty(addr.street.text),
      number: _nullIfEmpty(addr.number.text),
      complement: _nullIfEmpty(addr.complement.text),
      neighborhood: _nullIfEmpty(addr.neighborhood.text),
      addressState: addr.state.value,
      city: _nullIfEmpty(addr.city.text),
      residenceLocation: residenceLocation,
      isShelter: addr.isShelter.value ?? false,

      // Step 3 — Diagnósticos
      diagnoses: diagnosesFormState.entries.value
          .where((e) => e.isComplete)
          .map((e) => Diagnosis.create(
                id: IcdCode.create(e.icdCode.text.trim()).valueOrNull!,
                date: TimeStamp.fromDate(e.dateParsed!).valueOrNull,
                description: e.description.text.trim(),
              ))
          .where((r) => r.isSuccess)
          .map((r) => r.valueOrNull!)
          .toList(),
    );
  }

  // ── Submit ───────────────────────────────────────────────────
  Future<void> registerPatient() async {
    if (!validateCurrentStep()) return;
    final intent = buildIntent();
    await registerPatientCommand.execute(intent);
  }

  String? get errorMessage {
    final result = registerPatientCommand.result;
    if (result == null || result.isSuccess) return null;
    return (result as Failure).error.toString();
  }

  // ── Helpers ──────────────────────────────────────────────────
  String? _nullIfEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  // ── Dispose ──────────────────────────────────────────────────
  @override
  void dispose() {
    referencePersonFormState.dispose();
    documentsFormState.dispose();
    addressFormState.dispose();
    diagnosesFormState.dispose();
    currentStep.dispose();
    showStepErrors.dispose();
    super.dispose();
  }
}
