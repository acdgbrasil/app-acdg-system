import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../../data/commands/assessment_intents.dart';
import '../../../logic/use_case/assessment/update_socio_economic_use_case.dart';
import '../../../logic/use_case/registry/get_patient_use_case.dart';
import '../../../logic/use_case/shared/get_lookup_table_use_case.dart';
import '../../shared/models/benefit_row.dart';
import '../../shared/models/member_option.dart';
import '../models/socio_economic_form_state.dart';

/// ViewModel for the Socio-Economic assessment page.
///
/// Follows MVVM Gold Standard:
/// - Commands for all async operations (no manual notifyListeners)
/// - FormState holds mutable UI state + dirty tracking
/// - Zero domain serialization — delegates to UseCase/Mapper
class SocioEconomicViewModel extends BaseViewModel {
  SocioEconomicViewModel({
    required this.patientId,
    required GetPatientUseCase getPatientUseCase,
    required UpdateSocioEconomicUseCase updateSocioEconomicUseCase,
    required GetLookupTableUseCase getLookupTableUseCase,
  }) : _getPatientUseCase = getPatientUseCase,
       _updateSocioEconomicUseCase = updateSocioEconomicUseCase,
       _getLookupTableUseCase = getLookupTableUseCase {
    loadCommand = Command0<void>(_load);
    saveCommand = Command0<void>(_save);
    _loadLookups();
  }

  final String patientId;
  final GetPatientUseCase _getPatientUseCase;
  final UpdateSocioEconomicUseCase _updateSocioEconomicUseCase;
  final GetLookupTableUseCase _getLookupTableUseCase;

  late final Command0<void> loadCommand;
  late final Command0<void> saveCommand;

  // ── FormState (owns all mutable UI state) ───────────────────

  final formState = SocioEconomicFormState();

  // ── Lookups ─────────────────────────────────────────────────

  List<LookupItem> _benefitTypeLookup = [];
  List<LookupItem> get benefitTypeLookup => _benefitTypeLookup;

  Future<void> _loadLookups() async {
    final r = await _getLookupTableUseCase.execute('dominio_tipo_beneficio');
    if (r case Success(:final value)) {
      _benefitTypeLookup = value;
    }
    notifyListeners();
  }

  // ── Load ────────────────────────────────────────────────────

  Future<Result<void>> _load() async {
    final result = await _getPatientUseCase.execute(patientId);

    switch (result) {
      case Success(:final value):
        _populateFormState(value);
      case Failure():
        formState.patientName = '';
    }

    return const Success(null);
  }

  void _populateFormState(Patient patient) {
    final pd = patient.personalData;
    formState.patientName =
        '${pd?.firstName ?? ''} ${pd?.lastName ?? ''}'.trim();

    formState.familyMembers = [
      MemberOption(
        id: patient.personId.value,
        label: formState.patientName.isNotEmpty
            ? formState.patientName
            : 'Pessoa de referencia',
      ),
      ...patient.familyMembers.map(
        (m) => MemberOption(
          id: m.personId.value,
          label: m.fullName ?? 'Membro',
        ),
      ),
    ];

    final ses = patient.socioeconomicSituation;
    if (ses != null) {
      formState
        ..totalFamilyIncome = ses.totalFamilyIncome
        ..receivesSocialBenefit = ses.receivesSocialBenefit
        ..mainSourceOfIncome = ses.mainSourceOfIncome
        ..hasUnemployed = ses.hasUnemployed
        ..socialBenefits = ses.socialBenefits.items
            .map(
              (b) => BenefitRow(
                benefitName: b.benefitName,
                amount: b.amount,
                beneficiaryId: b.beneficiaryId.value,
                benefitTypeId: b.benefitTypeId.value.toUpperCase(),
              ),
            )
            .toList()
        ..saveOriginals();
    }
  }

  // ── Save ────────────────────────────────────────────────────

  Future<Result<void>> _save() async {
    if (!formState.canSave) {
      return const Success(null);
    }

    final PatientId patId;
    switch (PatientId.create(patientId)) {
      case Success(:final value):
        patId = value;
      case Failure(:final error):
        return Failure(error);
    }

    // Build domain benefits from form rows
    final benefits = <SocialBenefit>[];
    for (final b in formState.socialBenefits) {
      if (b.benefitName.isEmpty ||
          b.beneficiaryId == null ||
          b.benefitTypeId == null) {
        continue;
      }

      final PersonId bid;
      switch (PersonId.create(b.beneficiaryId!)) {
        case Success(:final value):
          bid = value;
        case Failure(:final error):
          return Failure(error);
      }

      final LookupId typeId;
      switch (LookupId.create(b.benefitTypeId!)) {
        case Success(:final value):
          typeId = value;
        case Failure(:final error):
          return Failure(error);
      }

      final sbResult = SocialBenefit.create(
        benefitName: b.benefitName,
        benefitTypeId: typeId,
        amount: b.amount,
        beneficiaryId: bid,
      );

      switch (sbResult) {
        case Success(:final value):
          benefits.add(value);
        case Failure(:final error):
          return Failure(error);
      }
    }

    final intent = UpdateSocioEconomicIntent(
      patientId: patId,
      totalFamilyIncome: formState.totalFamilyIncome,
      incomePerCapita: formState.incomePerCapita,
      receivesSocialBenefit: formState.receivesSocialBenefit,
      socialBenefits: benefits,
      mainSourceOfIncome: formState.mainSourceOfIncome.trim(),
      hasUnemployed: formState.hasUnemployed,
    );

    final result = await _updateSocioEconomicUseCase.execute(intent);

    if (result.isSuccess) {
      formState.saveOriginals();
    }

    return result;
  }

  @override
  void onDispose() {
    loadCommand.dispose();
    saveCommand.dispose();
  }
}
