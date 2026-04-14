import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../../data/commands/registry_intents.dart';
import '../../../logic/use_case/registry/get_patient_use_case.dart';
import '../../../logic/use_case/registry/update_social_identity_use_case.dart';
import '../../../logic/use_case/shared/get_lookup_table_use_case.dart';

class SocialIdentityViewModel extends BaseViewModel {
  SocialIdentityViewModel({
    required this.patientId,
    required GetPatientUseCase getPatientUseCase,
    required UpdateSocialIdentityUseCase updateSocialIdentityUseCase,
    required GetLookupTableUseCase getLookupTableUseCase,
  }) : _getPatientUseCase = getPatientUseCase,
       _updateSocialIdentityUseCase = updateSocialIdentityUseCase,
       _getLookupTableUseCase = getLookupTableUseCase {
    loadCommand = Command0<void>(_load);
    saveCommand = Command0<void>(_save);
    _loadLookups();
    print('🏗️ Created with patientId=$patientId');
  }


  final String patientId;
  final GetPatientUseCase _getPatientUseCase;
  final UpdateSocialIdentityUseCase _updateSocialIdentityUseCase;
  final GetLookupTableUseCase _getLookupTableUseCase;

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

  void updateTypeId(String value) {
    _typeId = value;
    notifyListeners();
  }

  void updateOtherDescription(String value) {
    _otherDescription = value;
    notifyListeners();
  }

  Future<void> _loadLookups() async {
    print('📋 Loading lookups...');
    final result = await _getLookupTableUseCase.execute(
      'dominio_tipo_identidade',
    );
    switch (result) {
      case Success(:final value):
        _identityTypeLookup = value;
        print(
          '📋 Lookup loaded: dominio_tipo_identidade (${value.length} items)',
        );
      case Failure(:final error):
        print('📋 Lookup FAILED: dominio_tipo_identidade ${error}');
    }
    notifyListeners();
  }

  Future<Result<void>> _load() async {
    print('⬇️ _load START for patient=$patientId');
    final result = await _getPatientUseCase.execute(patientId);
    switch (result) {
      case Success(:final value):
        final pd = value.personalData;
        _patientName = '${pd?.firstName ?? ''} ${pd?.lastName ?? ''}'.trim();
        final si = value.socialIdentity;
        if (si != null) {
          _typeId = si.typeId.value.toUpperCase();
          _otherDescription = si.otherDescription ?? '';
          _originalTypeId = _typeId;
          _originalOtherDescription = _otherDescription;
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
    final LookupId lookupId;
    switch (LookupId.create(_typeId!)) {
      case Success(:final value):
        lookupId = value;
      case Failure(:final error):
        return Failure(error);
    }
    final identityResult = SocialIdentity.create(
      typeId: lookupId,
      otherDescription: _otherDescription.isEmpty ? null : _otherDescription,
    );
    switch (identityResult) {
      case Success(:final value):
        final intent = UpdateSocialIdentityIntent(
          patientId: patId,
          identity: value,
        );
        final result = await _updateSocialIdentityUseCase.execute(intent);
        if (result.isSuccess) {
          print('⬆️ _save SUCCESS');
          _originalTypeId = _typeId;
          _originalOtherDescription = _otherDescription;
          notifyListeners();
        } else {
          print('⬆️ _save FAILED ${'see error above'}');
        }
        return result;
      case Failure(:final error):
        print('⬆️ _save FAILED ${error}');
        return Failure(error);
    }
  }

  @override
  void onDispose() {
    print('🗑️ Disposing');
    loadCommand.dispose();
    saveCommand.dispose();
  }
}
