import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../../data/repositories/lookup_repository.dart';
import '../../../logic/use_case/care/update_intake_info_use_case.dart';
import '../../../logic/use_case/registry/get_patient_use_case.dart';
import '../../home/mappers/intake_info_detail_mapper.dart';
import '../../home/models/intake_info_detail.dart';

class IntakeInfoViewModel extends BaseViewModel {
  IntakeInfoViewModel({
    required this.patientId,
    required GetPatientUseCase getPatientUseCase,
    required UpdateIntakeInfoUseCase updateIntakeInfoUseCase,
    required LookupRepository lookupRepository,
  }) : _getPatientUseCase = getPatientUseCase,
       _updateIntakeInfoUseCase = updateIntakeInfoUseCase,
       _lookupRepository = lookupRepository {
    loadCommand = Command0<void>(_load);
    saveCommand = Command0<void>(_save);
    _loadLookups();
  }

  static final _log = AcdgLogger.get('IntakeInfoViewModel');

  final String patientId;
  final GetPatientUseCase _getPatientUseCase;
  final UpdateIntakeInfoUseCase _updateIntakeInfoUseCase;
  final LookupRepository _lookupRepository;

  late final Command0<void> loadCommand;
  late final Command0<void> saveCommand;

  // ── Lookups ────────────────────────────────────────────────

  List<LookupItem> _ingressTypeLookup = [];
  List<LookupItem> get ingressTypeLookup => _ingressTypeLookup;

  List<LookupItem> _socialProgramsLookup = [];
  List<LookupItem> get socialProgramsLookup => _socialProgramsLookup;

  bool _lookupsLoaded = false;
  bool get lookupsLoaded => _lookupsLoaded;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Form state ─────────────────────────────────────────────

  String? _ingressTypeId;
  String? get ingressTypeId => _ingressTypeId;

  String _originName = '';
  String get originName => _originName;

  String _originContact = '';
  String get originContact => _originContact;

  String _serviceReason = '';
  String get serviceReason => _serviceReason;

  List<LinkedProgramDetail> _linkedPrograms = [];
  List<LinkedProgramDetail> get linkedPrograms => _linkedPrograms;

  String _patientName = '';
  String get patientName => _patientName;

  // ── Original state for dirty checking ──────────────────────

  String? _originalIngressTypeId;
  String _originalOriginName = '';
  String _originalOriginContact = '';
  String _originalServiceReason = '';
  List<LinkedProgramDetail> _originalLinkedPrograms = [];

  bool get canSave =>
      _ingressTypeId != null &&
      _serviceReason.trim().isNotEmpty &&
      _isDirty;

  bool get _isDirty =>
      _ingressTypeId != _originalIngressTypeId ||
      _originName != _originalOriginName ||
      _originContact != _originalOriginContact ||
      _serviceReason != _originalServiceReason ||
      !_programsEqual(_linkedPrograms, _originalLinkedPrograms);

  bool get hasData => _ingressTypeId != null;

  // ── Actions ────────────────────────────────────────────────

  void updateIngressType(String id) {
    _ingressTypeId = id;
    notifyListeners();
  }

  void updateOriginName(String value) {
    _originName = value;
    notifyListeners();
  }

  void updateOriginContact(String value) {
    _originContact = value;
    notifyListeners();
  }

  void updateServiceReason(String value) {
    _serviceReason = value;
    notifyListeners();
  }

  void toggleProgram(String programId) {
    final exists = _linkedPrograms.any((p) => p.programId == programId);
    if (exists) {
      _linkedPrograms = _linkedPrograms
          .where((p) => p.programId != programId)
          .toList();
    } else {
      _linkedPrograms = [
        ..._linkedPrograms,
        LinkedProgramDetail(programId: programId),
      ];
    }
    notifyListeners();
  }

  // ── Load ───────────────────────────────────────────────────

  Future<void> _loadLookups() async {
    _log.info('Loading lookups');
    final errors = <String>[];

    final ingressResult = await _lookupRepository.getLookupTable(
      'dominio_tipo_ingresso',
    );
    switch (ingressResult) {
      case Success(:final value):
        _ingressTypeLookup = value;
      case Failure(:final error):
        _log.severe('Failed to load ingress type lookups', error);
        errors.add('Falha ao carregar tipos de ingresso');
    }

    final programsResult = await _lookupRepository.getLookupTable(
      'dominio_programa_social',
    );
    switch (programsResult) {
      case Success(:final value):
        _socialProgramsLookup = value;
      case Failure(:final error):
        _log.severe('Failed to load social programs lookups', error);
        errors.add('Falha ao carregar programas sociais');
    }

    if (errors.isNotEmpty) {
      _errorMessage = errors.join('; ');
    }

    _lookupsLoaded = true;
    notifyListeners();
  }

  Future<Result<void>> _load() async {
    _log.info('Loading patient: $patientId');
    final result = await _getPatientUseCase.execute(patientId);

    switch (result) {
      case Success(:final value):
        final pd = value.personalData;
        final first = pd?.firstName ?? '';
        final last = pd?.lastName ?? '';
        _patientName = '$first $last'.trim();

        final intake = value.intakeInfo;
        if (intake != null) {
          _ingressTypeId = intake.ingressTypeId.value;
          _originName = intake.originName ?? '';
          _originContact = intake.originContact ?? '';
          _serviceReason = intake.serviceReason;
          _linkedPrograms = intake.linkedSocialPrograms
              .map(
                (p) => LinkedProgramDetail(
                  programId: p.programId.value,
                  observation: p.observation,
                ),
              )
              .toList();

          _originalIngressTypeId = _ingressTypeId;
          _originalOriginName = _originName;
          _originalOriginContact = _originContact;
          _originalServiceReason = _serviceReason;
          _originalLinkedPrograms = List.of(_linkedPrograms);
        }
      case Failure(:final error):
        _log.severe('Failed to load patient', error);
        _errorMessage = 'Falha ao carregar paciente';
    }

    notifyListeners();
    return const Success(null);
  }

  Future<Result<void>> _save() async {
    if (!canSave) return const Success(null);

    final detail = IntakeInfoDetail(
      ingressTypeId: _ingressTypeId!,
      originName: _originName.isEmpty ? null : _originName,
      originContact: _originContact.isEmpty ? null : _originContact,
      serviceReason: _serviceReason,
      linkedSocialPrograms: _linkedPrograms,
    );

    final PatientId patId;
    switch (PatientId.create(patientId)) {
      case Success(:final value):
        patId = value;
      case Failure(:final error):
        return Failure(error);
    }

    final intentResult = IntakeInfoDetailMapper.toIntent(
      detail,
      patientId: patId,
    );

    switch (intentResult) {
      case Success(:final value):
        final result = await _updateIntakeInfoUseCase.execute(value);
        if (result.isSuccess) {
          _originalIngressTypeId = _ingressTypeId;
          _originalOriginName = _originName;
          _originalOriginContact = _originContact;
          _originalServiceReason = _serviceReason;
          _originalLinkedPrograms = List.of(_linkedPrograms);
          notifyListeners();
        }
        return result;
      case Failure(:final error):
        return Failure(error);
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  bool _programsEqual(
    List<LinkedProgramDetail> a,
    List<LinkedProgramDetail> b,
  ) {
    if (a.length != b.length) return false;
    final aIds = a.map((p) => p.programId).toSet();
    final bIds = b.map((p) => p.programId).toSet();
    return aIds.length == bIds.length && aIds.containsAll(bIds);
  }

  @override
  void onDispose() {
    _log.info('Disposing IntakeInfoViewModel');
    loadCommand.dispose();
    saveCommand.dispose();
  }
}
