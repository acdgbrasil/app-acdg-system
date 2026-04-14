import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../../data/commands/assessment_intents.dart';
import '../../../logic/use_case/assessment/update_community_support_use_case.dart';
import '../../../logic/use_case/registry/get_patient_use_case.dart';

class CommunitySupportViewModel extends BaseViewModel {
  CommunitySupportViewModel({
    required this.patientId,
    required GetPatientUseCase getPatientUseCase,
    required UpdateCommunitySupportUseCase updateCommunitySupportUseCase,
  }) : _getPatientUseCase = getPatientUseCase,
       _updateCommunitySupportUseCase = updateCommunitySupportUseCase {
    loadCommand = Command0<void>(_load);
    saveCommand = Command0<void>(_save);
    print('🏗️ Created with patientId=$patientId');
  }


  final String patientId;
  final GetPatientUseCase _getPatientUseCase;
  final UpdateCommunitySupportUseCase _updateCommunitySupportUseCase;

  late final Command0<void> loadCommand;
  late final Command0<void> saveCommand;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Form state ─────────────────────────────────────────────

  String _patientName = '';
  String get patientName => _patientName;

  bool _hasRelativeSupport = false;
  bool get hasRelativeSupport => _hasRelativeSupport;

  bool _hasNeighborSupport = false;
  bool get hasNeighborSupport => _hasNeighborSupport;

  String _familyConflicts = '';
  String get familyConflicts => _familyConflicts;

  bool _patientParticipatesInGroups = false;
  bool get patientParticipatesInGroups => _patientParticipatesInGroups;

  bool _familyParticipatesInGroups = false;
  bool get familyParticipatesInGroups => _familyParticipatesInGroups;

  bool _patientHasAccessToLeisure = false;
  bool get patientHasAccessToLeisure => _patientHasAccessToLeisure;

  bool _facesDiscrimination = false;
  bool get facesDiscrimination => _facesDiscrimination;

  // ── Original state ─────────────────────────────────────────

  bool _originalHasRelativeSupport = false;
  bool _originalHasNeighborSupport = false;
  String _originalFamilyConflicts = '';
  bool _originalPatientParticipatesInGroups = false;
  bool _originalFamilyParticipatesInGroups = false;
  bool _originalPatientHasAccessToLeisure = false;
  bool _originalFacesDiscrimination = false;
  bool _hasLoadedData = false;

  bool get hasData => _hasLoadedData;

  /// CSN-002: familyConflicts max 300 characters
  bool get _conflictsValid => _familyConflicts.length <= 300;

  bool get canSave => _conflictsValid && _isDirty;

  bool get _isDirty =>
      _hasRelativeSupport != _originalHasRelativeSupport ||
      _hasNeighborSupport != _originalHasNeighborSupport ||
      _familyConflicts != _originalFamilyConflicts ||
      _patientParticipatesInGroups != _originalPatientParticipatesInGroups ||
      _familyParticipatesInGroups != _originalFamilyParticipatesInGroups ||
      _patientHasAccessToLeisure != _originalPatientHasAccessToLeisure ||
      _facesDiscrimination != _originalFacesDiscrimination;

  int get conflictsRemaining => 300 - _familyConflicts.length;

  // ── Actions ────────────────────────────────────────────────

  void toggleRelativeSupport() {
    _hasRelativeSupport = !_hasRelativeSupport;
    notifyListeners();
  }

  void toggleNeighborSupport() {
    _hasNeighborSupport = !_hasNeighborSupport;
    notifyListeners();
  }

  void updateFamilyConflicts(String value) {
    _familyConflicts = value;
    notifyListeners();
  }

  void togglePatientParticipates() {
    _patientParticipatesInGroups = !_patientParticipatesInGroups;
    notifyListeners();
  }

  void toggleFamilyParticipates() {
    _familyParticipatesInGroups = !_familyParticipatesInGroups;
    notifyListeners();
  }

  void toggleLeisureAccess() {
    _patientHasAccessToLeisure = !_patientHasAccessToLeisure;
    notifyListeners();
  }

  void toggleDiscrimination() {
    _facesDiscrimination = !_facesDiscrimination;
    notifyListeners();
  }

  // ── Load ───────────────────────────────────────────────────

  Future<Result<void>> _load() async {
    print('⬇️ _load START for patient=$patientId');
    final result = await _getPatientUseCase.execute(patientId);

    switch (result) {
      case Success(:final value):
        final pd = value.personalData;
        final first = pd?.firstName ?? '';
        final last = pd?.lastName ?? '';
        _patientName = '$first $last'.trim();

        final csn = value.communitySupportNetwork;
        if (csn != null) {
          _hasRelativeSupport = csn.hasRelativeSupport;
          _hasNeighborSupport = csn.hasNeighborSupport;
          _familyConflicts = csn.familyConflicts;
          _patientParticipatesInGroups = csn.patientParticipatesInGroups;
          _familyParticipatesInGroups = csn.familyParticipatesInGroups;
          _patientHasAccessToLeisure = csn.patientHasAccessToLeisure;
          _facesDiscrimination = csn.facesDiscrimination;
          _saveOriginals();
        }
        _hasLoadedData = true;
        print(
          '⬇️ _load SUCCESS — hasData=$_hasLoadedData, patientName=$_patientName',
        );
      case Failure(:final error):
        print('⬇️ _load FAILED ${error}');
        _errorMessage = 'Falha ao carregar paciente';
    }

    notifyListeners();
    print('🔔 notifyListeners() called after _load');
    return const Success(null);
  }

  // ── Save ───────────────────────────────────────────────────

  Future<Result<void>> _save() async {
    print('⬆️ _save START — canSave=$canSave');
    if (!canSave) {
      print('⬆️ _save SKIPPED — canSave is false');
      return const Success(null);
    }

    final PatientId patId;
    switch (PatientId.create(patientId)) {
      case Success(:final value):
        patId = value;
      case Failure(:final error):
        return Failure(error);
    }

    final intent = UpdateCommunitySupportIntent(
      patientId: patId,
      hasRelativeSupport: _hasRelativeSupport,
      hasNeighborSupport: _hasNeighborSupport,
      familyConflicts: _familyConflicts.trim(),
      patientParticipatesInGroups: _patientParticipatesInGroups,
      familyParticipatesInGroups: _familyParticipatesInGroups,
      patientHasAccessToLeisure: _patientHasAccessToLeisure,
      facesDiscrimination: _facesDiscrimination,
    );

    final result = await _updateCommunitySupportUseCase.execute(intent);
    if (result.isSuccess) {
      print('⬆️ _save SUCCESS');
      _saveOriginals();
      notifyListeners();
    } else {
      print('⬆️ _save FAILED ${'see error above'}');
    }
    return result;
  }

  void _saveOriginals() {
    _originalHasRelativeSupport = _hasRelativeSupport;
    _originalHasNeighborSupport = _hasNeighborSupport;
    _originalFamilyConflicts = _familyConflicts;
    _originalPatientParticipatesInGroups = _patientParticipatesInGroups;
    _originalFamilyParticipatesInGroups = _familyParticipatesInGroups;
    _originalPatientHasAccessToLeisure = _patientHasAccessToLeisure;
    _originalFacesDiscrimination = _facesDiscrimination;
  }

  @override
  void onDispose() {
    print('🗑️ Disposing');
    loadCommand.dispose();
    saveCommand.dispose();
  }
}
