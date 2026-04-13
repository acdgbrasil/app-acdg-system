import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../../data/commands/registry_intents.dart';
import '../../../data/repositories/lookup_repository.dart';
import '../../../logic/use_case/registry/get_patient_use_case.dart';
import '../../../logic/use_case/registry/update_social_identity_use_case.dart';

class SocialIdentityViewModel extends BaseViewModel {
  SocialIdentityViewModel({
    required this.patientId,
    required GetPatientUseCase getPatientUseCase,
    required UpdateSocialIdentityUseCase updateSocialIdentityUseCase,
    required LookupRepository lookupRepository,
  }) : _getPatientUseCase = getPatientUseCase,
       _updateSocialIdentityUseCase = updateSocialIdentityUseCase,
       _lookupRepository = lookupRepository {
    loadCommand = Command0<void>(_load);
    saveCommand = Command0<void>(_save);
    _loadLookups();
  }

  final String patientId;
  final GetPatientUseCase _getPatientUseCase;
  final UpdateSocialIdentityUseCase _updateSocialIdentityUseCase;
  final LookupRepository _lookupRepository;

  late final Command0<void> loadCommand;
  late final Command0<void> saveCommand;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _patientName = '';
  String get patientName => _patientName;

  List<LookupItem> _identityTypeLookup = [];
  List<LookupItem> get identityTypeLookup => _identityTypeLookup;

  String? _typeId;
  String? get typeId => _typeId;

  String _otherDescription = '';
  String get otherDescription => _otherDescription;

  String? _originalTypeId;
  String _originalOtherDescription = '';
  bool _hasLoadedData = false;

  bool get hasData => _hasLoadedData;
  bool get canSave => _typeId != null && _isDirty;
  bool get _isDirty =>
      _typeId != _originalTypeId ||
      _otherDescription != _originalOtherDescription;

  void updateTypeId(String value) { _typeId = value; notifyListeners(); }
  void updateOtherDescription(String value) { _otherDescription = value; notifyListeners(); }

  Future<void> _loadLookups() async {
    final result = await _lookupRepository.getLookupTable('dominio_tipo_identidade');
    if (result case Success(:final value)) _identityTypeLookup = value;
    notifyListeners();
  }

  Future<Result<void>> _load() async {
    final result = await _getPatientUseCase.execute(patientId);
    switch (result) {
      case Success(:final value):
        final pd = value.personalData;
        _patientName = '${pd?.firstName ?? ''} ${pd?.lastName ?? ''}'.trim();
        final si = value.socialIdentity;
        if (si != null) {
          _typeId = si.typeId.value;
          _otherDescription = si.otherDescription ?? '';
          _originalTypeId = _typeId;
          _originalOtherDescription = _otherDescription;
        }
        _hasLoadedData = true;
      case Failure(:final error):
        _errorMessage = 'Falha ao carregar paciente';
    }
    notifyListeners();
    return const Success(null);
  }

  Future<Result<void>> _save() async {
    if (!canSave) return const Success(null);
    final PatientId patId;
    switch (PatientId.create(patientId)) {
      case Success(:final value): patId = value;
      case Failure(:final error): return Failure(error);
    }
    final LookupId lookupId;
    switch (LookupId.create(_typeId!)) {
      case Success(:final value): lookupId = value;
      case Failure(:final error): return Failure(error);
    }
    final identityResult = SocialIdentity.create(
      typeId: lookupId,
      otherDescription: _otherDescription.isEmpty ? null : _otherDescription,
    );
    switch (identityResult) {
      case Success(:final value):
        final intent = UpdateSocialIdentityIntent(patientId: patId, identity: value);
        final result = await _updateSocialIdentityUseCase.execute(intent);
        if (result.isSuccess) {
          _originalTypeId = _typeId;
          _originalOtherDescription = _otherDescription;
          notifyListeners();
        }
        return result;
      case Failure(:final error):
        return Failure(error);
    }
  }

  @override
  void onDispose() { loadCommand.dispose(); saveCommand.dispose(); }
}
