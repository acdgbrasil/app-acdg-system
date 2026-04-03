import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';

import '../models/family_member_model.dart';
import '../models/add_member_result.dart';

/// ViewModel for the standalone Family Composition screen.
///
/// Follows the MVVM Gold Standard:
/// - Commands for all async operations (no manual loading flags)
/// - Domain entities as input (no JSON parsing)
/// - Age profile delegated to domain model
class FamilyCompositionViewModel extends BaseViewModel {
  FamilyCompositionViewModel({
    required this.patientId,
    required GetPatientUseCase getPatientUseCase,
    required AddFamilyMemberUseCase addFamilyMemberUseCase,
    required RemoveFamilyMemberUseCase removeFamilyMemberUseCase,
    required UpdatePrimaryCaregiverUseCase updatePrimaryCaregiverUseCase,
    required LookupRepository lookupRepository,
  })  : _getPatientUseCase = getPatientUseCase,
        _lookupRepository = lookupRepository {
    loadPatientCommand = Command0<void>(_loadPatient);
    addMemberCommand = Command1<void, AddFamilyMemberIntent>(
      (intent) => addFamilyMemberUseCase.execute(intent),
    );
    removeMemberCommand = Command1<void, RemoveFamilyMemberIntent>(
      (intent) => removeFamilyMemberUseCase.execute(intent),
    );
    assignCaregiverCommand = Command1<void, UpdatePrimaryCaregiverIntent>(
      (intent) => updatePrimaryCaregiverUseCase.execute(intent),
    );
    _loadLookups();
  }

  final String patientId;
  final GetPatientUseCase _getPatientUseCase;
  final LookupRepository _lookupRepository;

  // ── Commands ────────────────────────────────────────────────
  late final Command0<void> loadPatientCommand;
  late final Command1<void, AddFamilyMemberIntent> addMemberCommand;
  late final Command1<void, RemoveFamilyMemberIntent> removeMemberCommand;
  late final Command1<void, UpdatePrimaryCaregiverIntent> assignCaregiverCommand;

  // ── State (private fields + public getters + notifyListeners) ──
  List<FamilyMemberModel> _members = [];
  List<FamilyMemberModel> get members => _members;

  List<LookupItem> _parentescoLookup = [];
  List<LookupItem> get parentescoLookup => _parentescoLookup;

  String? _prRelationshipId;

  // ── Computed getters ────────────────────────────────────────

  FamilyMemberModel? get referencePerson =>
      _members.where((m) => m.isReferencePerson).firstOrNull;

  FamilyMemberModel? get currentCaregiver =>
      _members.where((m) => m.isPrimaryCaregiver).firstOrNull;

  bool get hasCaregiver => currentCaregiver != null;

  bool get isEmpty => _members.where((m) => !m.isReferencePerson).isEmpty;

  /// Age profile: 8 ranges computed from member ages.
  /// Delegated to [FamilyMemberModel.age] — the VM only aggregates.
  Map<String, int> get ageProfile {
    final profile = <String, int>{
      '0-6': 0, '7-14': 0, '15-17': 0, '18-29': 0,
      '30-59': 0, '60-64': 0, '65-69': 0, '70+': 0,
    };

    for (final member in _members) {
      final age = member.age;
      final key = switch (age) {
        <= 6 => '0-6',
        <= 14 => '7-14',
        <= 17 => '15-17',
        <= 29 => '18-29',
        <= 59 => '30-59',
        <= 64 => '60-64',
        <= 69 => '65-69',
        _ => '70+',
      };
      profile[key] = profile[key]! + 1;
    }

    return profile;
  }

  // ── Load ────────────────────────────────────────────────────

  Future<void> _loadLookups() async {
    final result = await _lookupRepository.getLookupTable('dominio_parentesco');
    switch (result) {
      case Success(:final value):
        _parentescoLookup = value;
        final pessoaRef = value.where((i) => i.codigo == 'PESSOA_REFERENCIA');
        if (pessoaRef.isNotEmpty) _prRelationshipId = pessoaRef.first.id;
      case Failure():
        break;
    }
    notifyListeners();
  }

  Future<Result<void>> _loadPatient() async {
    final result = await _getPatientUseCase.execute(patientId);

    switch (result) {
      case Success(:final value):
        _members = _translateMembers(value);
      case Failure():
        _members = [];
    }

    notifyListeners();
    return const Success(null);
  }

  // ── Actions ─────────────────────────────────────────────────

  Future<void> addMember(AddFamilyMemberIntent intent) async {
    await addMemberCommand.execute(intent);
    if (addMemberCommand.completed) await loadPatientCommand.execute();
  }

  Future<void> removeMember(PersonId memberId) async {
    final PatientId patId;
    switch (PatientId.create(patientId)) {
      case Success(:final value): patId = value;
      case Failure(): return;
    }

    await removeMemberCommand.execute(RemoveFamilyMemberIntent(
      patientId: patId,
      memberPersonId: memberId,
    ));
    if (removeMemberCommand.completed) await loadPatientCommand.execute();
  }

  Future<void> assignCaregiver(PersonId memberId) async {
    final PatientId patId;
    switch (PatientId.create(patientId)) {
      case Success(:final value): patId = value;
      case Failure(): return;
    }

    await assignCaregiverCommand.execute(UpdatePrimaryCaregiverIntent(
      patientId: patId,
      memberPersonId: memberId,
    ));
    if (assignCaregiverCommand.completed) await loadPatientCommand.execute();
  }

  /// Handles the full save flow from the add/edit modal result.
  /// Resolves lookups, builds intent, orchestrates add/edit + caregiver assignment.
  Future<void> handleModalSave(AddMemberResult result, {FamilyMemberModel? existing}) async {
    final PatientId patId;
    switch (PatientId.create(patientId)) {
      case Success(:final value): patId = value;
      case Failure(): return;
    }

    final lookupItem = _parentescoLookup
        .where((i) => i.codigo == result.relationshipCode)
        .firstOrNull;

    final intent = AddFamilyMemberIntent(
      patientId: patId,
      firstName: result.name.split(' ').first,
      lastName: result.name.split(' ').skip(1).join(' '),
      relationshipId: lookupItem?.id ?? result.relationshipCode,
      birthDate: result.birthDate,
      prRelationshipId: lookupItem?.id ?? result.relationshipCode,
      isPrimaryCaregiver: false,
      residesWithPatient: result.residesWithPatient,
      hasDisability: result.hasDisability,
      requiredDocuments: result.requiredDocuments
          .map((d) => RequiredDocument.values.where((v) => v.value == d).firstOrNull)
          .whereType<RequiredDocument>()
          .toList(),
    );

    if (existing != null) {
      final PersonId oldId;
      switch (PersonId.create(existing.personId)) {
        case Success(:final value): oldId = value;
        case Failure(): return;
      }
      await removeMember(oldId);
    }

    await addMember(intent);

    if (result.isPrimaryCaregiver) {
      await loadPatientCommand.execute();
      _assignCaregiverToLastAdded();
    }
  }

  /// Handles remove with guard for reference person.
  Future<bool> handleRemove(FamilyMemberModel member) async {
    if (member.isReferencePerson) return false;

    final PersonId memberId;
    switch (PersonId.create(member.personId)) {
      case Success(:final value): memberId = value;
      case Failure(): return false;
    }
    await removeMember(memberId);
    return true;
  }

  /// Handles caregiver toggle with guard for reference person.
  /// Returns `true` if confirmation dialog is needed (existing caregiver).
  bool needsCaregiverConfirmation(FamilyMemberModel member) {
    return !member.isReferencePerson && !member.isPrimaryCaregiver && currentCaregiver != null;
  }

  /// Toggles caregiver status for a member.
  Future<void> handleCaregiverToggle(FamilyMemberModel member) async {
    if (member.isReferencePerson) return;

    final PersonId memberId;
    switch (PersonId.create(member.personId)) {
      case Success(:final value): memberId = value;
      case Failure(): return;
    }
    await assignCaregiver(memberId);
  }

  void _assignCaregiverToLastAdded() {
    final newMember = _members
        .where((m) => !m.isReferencePerson && !m.isPrimaryCaregiver)
        .lastOrNull;
    if (newMember != null) {
      final PersonId newId;
      switch (PersonId.create(newMember.personId)) {
        case Success(:final value): newId = value;
        case Failure(): return;
      }
      assignCaregiver(newId);
    }
  }

  /// Updates required documents for a member locally (not persisted until save).
  void toggleDocument(int memberIndex, String doc, bool checked) {
    if (memberIndex < 0 || memberIndex >= _members.length) return;
    final member = _members[memberIndex];
    if (member.isReferencePerson) return;

    final docs = {...member.requiredDocuments};
    if (checked) {
      docs.add(doc);
    } else {
      docs.remove(doc);
    }
    _members = [
      for (var i = 0; i < _members.length; i++)
        if (i == memberIndex) member.copyWith(requiredDocuments: docs)
        else _members[i],
    ];
    notifyListeners();
  }

  // ── Domain → UI Translation ─────────────────────────────────

  /// Translates domain [FamilyMember] entities into UI [FamilyMemberModel]s.
  /// No JSON parsing — reads directly from typed domain objects.
  List<FamilyMemberModel> _translateMembers(Patient patient) {
    final members = <FamilyMemberModel>[];

    for (final fm in patient.familyMembers) {
      final relId = fm.relationshipId.value;
      final isPr = relId == _prRelationshipId;

      final lookupItem = _parentescoLookup
          .where((i) => i.id == relId)
          .firstOrNull;
      final relLabel = isPr
          ? 'Pessoa de Referência'
          : lookupItem?.descricao ?? relId;

      members.add(FamilyMemberModel(
        personId: fm.personId.value,
        relationshipLabel: relLabel,
        relationshipCode: lookupItem?.codigo ?? relId,
        birthDate: fm.birthDate.date,
        sex: isPr ? _sexLabel(patient) : '–',
        isReferencePerson: isPr,
        isPrimaryCaregiver: fm.isPrimaryCaregiver,
        residesWithPatient: fm.residesWithPatient,
        hasDisability: fm.hasDisability,
        requiredDocuments: fm.requiredDocuments.map((d) => d.value).toSet(),
      ));
    }

    // PR always first
    members.sort((a, b) {
      if (a.isReferencePerson) return -1;
      if (b.isReferencePerson) return 1;
      return 0;
    });

    // Fallback: if no PR identified (lookup not loaded), treat first as PR
    if (members.isNotEmpty && !members.any((m) => m.isReferencePerson)) {
      members[0] = members[0].copyWith(isReferencePerson: true);
    }

    return members;
  }

  /// Derives sex label for the reference person from personalData.
  String _sexLabel(Patient patient) {
    final sex = patient.personalData?.sex;
    return switch (sex) {
      Sex.masculino => 'Masculino',
      Sex.feminino => 'Feminino',
      _ => 'Outro',
    };
  }
}
