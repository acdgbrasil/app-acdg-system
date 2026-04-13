import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../../data/repositories/lookup_repository.dart';
import '../../../logic/use_case/assessment/update_health_status_use_case.dart';
import '../../../logic/use_case/registry/get_patient_use_case.dart';
import '../../home/mappers/health_status_detail_mapper.dart';
import '../../home/models/health_status_detail.dart';

/// Mutable UI model for a deficiency row.
class DeficiencyRow {
  String? memberId;
  String? deficiencyTypeId;
  bool needsConstantCare;
  String responsibleCaregiverName;

  DeficiencyRow({
    this.memberId,
    this.deficiencyTypeId,
    this.needsConstantCare = false,
    this.responsibleCaregiverName = '',
  });

  DeficiencyRow copy() => DeficiencyRow(
    memberId: memberId,
    deficiencyTypeId: deficiencyTypeId,
    needsConstantCare: needsConstantCare,
    responsibleCaregiverName: responsibleCaregiverName,
  );
}

/// Mutable UI model for a gestating member row.
class GestatingRow {
  String? memberId;
  int monthsGestation;
  bool startedPrenatalCare;

  GestatingRow({
    this.memberId,
    this.monthsGestation = 1,
    this.startedPrenatalCare = false,
  });

  GestatingRow copy() => GestatingRow(
    memberId: memberId,
    monthsGestation: monthsGestation,
    startedPrenatalCare: startedPrenatalCare,
  );
}

/// Simple member reference for dropdowns.
class MemberOption {
  final String id;
  final String label;

  const MemberOption({required this.id, required this.label});
}

class HealthStatusViewModel extends BaseViewModel {
  HealthStatusViewModel({
    required this.patientId,
    required GetPatientUseCase getPatientUseCase,
    required UpdateHealthStatusUseCase updateHealthStatusUseCase,
    required LookupRepository lookupRepository,
  }) : _getPatientUseCase = getPatientUseCase,
       _updateHealthStatusUseCase = updateHealthStatusUseCase,
       _lookupRepository = lookupRepository {
    loadCommand = Command0<void>(_load);
    saveCommand = Command0<void>(_save);
    _loadLookups();
  }

  static final _log = AcdgLogger.get('HealthStatusViewModel');

  final String patientId;
  final GetPatientUseCase _getPatientUseCase;
  final UpdateHealthStatusUseCase _updateHealthStatusUseCase;
  final LookupRepository _lookupRepository;

  late final Command0<void> loadCommand;
  late final Command0<void> saveCommand;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Lookups ────────────────────────────────────────────────

  List<LookupItem> _deficiencyTypeLookup = [];
  List<LookupItem> get deficiencyTypeLookup => _deficiencyTypeLookup;

  bool _lookupsLoaded = false;
  bool get lookupsLoaded => _lookupsLoaded;

  // ── Family members (for dropdowns) ─────────────────────────

  List<MemberOption> _familyMembers = [];
  List<MemberOption> get familyMembers => _familyMembers;

  // ── Form state ─────────────────────────────────────────────

  String _patientName = '';
  String get patientName => _patientName;

  bool _foodInsecurity = false;
  bool get foodInsecurity => _foodInsecurity;

  List<DeficiencyRow> _deficiencies = [];
  List<DeficiencyRow> get deficiencies => _deficiencies;

  List<GestatingRow> _gestatingMembers = [];
  List<GestatingRow> get gestatingMembers => _gestatingMembers;

  List<String> _constantCareNeeds = [];
  List<String> get constantCareNeeds => _constantCareNeeds;

  // ── Original state for dirty checking ──────────────────────

  bool _originalFoodInsecurity = false;
  int _originalDeficienciesCount = 0;
  int _originalGestatingCount = 0;
  int _originalCareNeedsCount = 0;
  bool _hasLoadedData = false;

  bool get hasData => _hasLoadedData;

  bool get canSave => _isDirty;

  bool get _isDirty =>
      _foodInsecurity != _originalFoodInsecurity ||
      _deficiencies.length != _originalDeficienciesCount ||
      _gestatingMembers.length != _originalGestatingCount ||
      _constantCareNeeds.length != _originalCareNeedsCount ||
      _deficiencies.isNotEmpty ||
      _gestatingMembers.isNotEmpty;

  // ── Actions: Food insecurity ───────────────────────────────

  void toggleFoodInsecurity() {
    _foodInsecurity = !_foodInsecurity;
    notifyListeners();
  }

  // ── Actions: Deficiencies ──────────────────────────────────

  void addDeficiency() {
    _deficiencies = [..._deficiencies, DeficiencyRow()];
    notifyListeners();
  }

  void removeDeficiency(int index) {
    _deficiencies = List.of(_deficiencies)..removeAt(index);
    notifyListeners();
  }

  void updateDeficiencyMember(int index, String memberId) {
    _deficiencies[index].memberId = memberId;
    notifyListeners();
  }

  void updateDeficiencyType(int index, String typeId) {
    _deficiencies[index].deficiencyTypeId = typeId;
    notifyListeners();
  }

  void toggleDeficiencyConstantCare(int index) {
    _deficiencies[index].needsConstantCare =
        !_deficiencies[index].needsConstantCare;
    notifyListeners();
  }

  void updateDeficiencyResponsible(int index, String name) {
    _deficiencies[index].responsibleCaregiverName = name;
    notifyListeners();
  }

  // ── Actions: Gestating ─────────────────────────────────────

  void addGestating() {
    _gestatingMembers = [..._gestatingMembers, GestatingRow()];
    notifyListeners();
  }

  void removeGestating(int index) {
    _gestatingMembers = List.of(_gestatingMembers)..removeAt(index);
    notifyListeners();
  }

  void updateGestatingMember(int index, String memberId) {
    _gestatingMembers[index].memberId = memberId;
    notifyListeners();
  }

  void updateGestatingMonths(int index, int months) {
    if (months >= 1 && months <= 10) {
      _gestatingMembers[index].monthsGestation = months;
      notifyListeners();
    }
  }

  void toggleGestatingPrenatal(int index) {
    _gestatingMembers[index].startedPrenatalCare =
        !_gestatingMembers[index].startedPrenatalCare;
    notifyListeners();
  }

  // ── Actions: Care needs ────────────────────────────────────

  void addCareNeed() {
    _constantCareNeeds = [..._constantCareNeeds, ''];
    notifyListeners();
  }

  void removeCareNeed(int index) {
    _constantCareNeeds = List.of(_constantCareNeeds)..removeAt(index);
    notifyListeners();
  }

  void updateCareNeedMember(int index, String memberId) {
    _constantCareNeeds[index] = memberId;
    notifyListeners();
  }

  // ── Load ───────────────────────────────────────────────────

  Future<void> _loadLookups() async {
    _log.info('Loading deficiency type lookups');
    final result = await _lookupRepository.getLookupTable(
      'dominio_tipo_deficiencia',
    );
    switch (result) {
      case Success(:final value):
        _deficiencyTypeLookup = value;
      case Failure(:final error):
        _log.severe('Failed to load deficiency type lookups', error);
        _errorMessage = 'Falha ao carregar tipos de deficiencia';
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

        // Build family member options for dropdowns
        final members = <MemberOption>[];
        // Add reference person
        members.add(MemberOption(
          id: value.personId.value,
          label: _patientName.isNotEmpty ? _patientName : 'Pessoa de referencia',
        ));
        // Add family members
        for (final member in value.familyMembers) {
          final name = member.fullName ?? 'Membro';
          members.add(MemberOption(
            id: member.personId.value,
            label: name,
          ));
        }
        _familyMembers = members;

        // Load existing health status
        final health = value.healthStatus;
        if (health != null) {
          _foodInsecurity = health.foodInsecurity;

          _deficiencies = health.deficiencies
              .map((d) => DeficiencyRow(
                    memberId: d.memberId.value,
                    deficiencyTypeId: d.deficiencyTypeId.value,
                    needsConstantCare: d.needsConstantCare,
                    responsibleCaregiverName:
                        d.responsibleCaregiverName ?? '',
                  ))
              .toList();

          _gestatingMembers = health.gestatingMembers
              .map((g) => GestatingRow(
                    memberId: g.memberId.value,
                    monthsGestation: g.monthsGestation,
                    startedPrenatalCare: g.startedPrenatalCare,
                  ))
              .toList();

          _constantCareNeeds =
              health.constantCareNeeds.map((id) => id.value).toList();

          _saveOriginals();
        }
        _hasLoadedData = true;
      case Failure(:final error):
        _log.severe('Failed to load patient', error);
        _errorMessage = 'Falha ao carregar paciente';
    }

    notifyListeners();
    return const Success(null);
  }

  // ── Save ───────────────────────────────────────────────────

  Future<Result<void>> _save() async {
    if (!canSave) return const Success(null);

    final detail = HealthStatusDetail(
      foodInsecurity: _foodInsecurity,
      deficiencies: _deficiencies
          .where((d) => d.memberId != null && d.deficiencyTypeId != null)
          .map((d) => DeficiencyDetail(
                memberId: d.memberId!,
                deficiencyTypeId: d.deficiencyTypeId!,
                needsConstantCare: d.needsConstantCare,
                responsibleCaregiverName:
                    d.responsibleCaregiverName.isEmpty
                        ? null
                        : d.responsibleCaregiverName,
              ))
          .toList(),
      gestatingMembers: _gestatingMembers
          .where((g) => g.memberId != null)
          .map((g) => GestatingMemberDetail(
                memberId: g.memberId!,
                monthsGestation: g.monthsGestation,
                startedPrenatalCare: g.startedPrenatalCare,
              ))
          .toList(),
      constantCareNeeds:
          _constantCareNeeds.where((id) => id.isNotEmpty).toList(),
    );

    final PatientId patId;
    switch (PatientId.create(patientId)) {
      case Success(:final value):
        patId = value;
      case Failure(:final error):
        return Failure(error);
    }

    final intentResult = HealthStatusDetailMapper.toIntent(
      detail,
      patientId: patId,
    );

    switch (intentResult) {
      case Success(:final value):
        final result = await _updateHealthStatusUseCase.execute(value);
        if (result.isSuccess) {
          _saveOriginals();
          notifyListeners();
        }
        return result;
      case Failure(:final error):
        return Failure(error);
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  void _saveOriginals() {
    _originalFoodInsecurity = _foodInsecurity;
    _originalDeficienciesCount = _deficiencies.length;
    _originalGestatingCount = _gestatingMembers.length;
    _originalCareNeedsCount = _constantCareNeeds.length;
  }

  @override
  void onDispose() {
    _log.info('Disposing HealthStatusViewModel');
    loadCommand.dispose();
    saveCommand.dispose();
  }
}
