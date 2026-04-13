import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../../data/commands/assessment_intents.dart';
import '../../../logic/use_case/assessment/update_housing_condition_use_case.dart';
import '../../../logic/use_case/registry/get_patient_use_case.dart';
import '../../home/mappers/housing_condition_detail_mapper.dart';
import '../../home/models/housing_condition_detail.dart';

class HousingConditionViewModel extends BaseViewModel {
  HousingConditionViewModel({
    required this.patientId,
    required GetPatientUseCase getPatientUseCase,
    required UpdateHousingConditionUseCase updateHousingConditionUseCase,
  }) : _getPatientUseCase = getPatientUseCase,
       _updateHousingConditionUseCase = updateHousingConditionUseCase {
    loadCommand = Command0<void>(_load);
    saveCommand = Command0<void>(_save);
  }

  static final _log = AcdgLogger.get('HousingConditionViewModel');

  final String patientId;
  final GetPatientUseCase _getPatientUseCase;
  final UpdateHousingConditionUseCase _updateHousingConditionUseCase;

  late final Command0<void> loadCommand;
  late final Command0<void> saveCommand;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Form state ─────────────────────────────────────────────

  String _patientName = '';
  String get patientName => _patientName;

  String? _type;
  String? get type => _type;

  String? _wallMaterial;
  String? get wallMaterial => _wallMaterial;

  int _numberOfRooms = 0;
  int get numberOfRooms => _numberOfRooms;

  int _numberOfBedrooms = 0;
  int get numberOfBedrooms => _numberOfBedrooms;

  int _numberOfBathrooms = 0;
  int get numberOfBathrooms => _numberOfBathrooms;

  String? _waterSupply;
  String? get waterSupply => _waterSupply;

  bool _hasPipedWater = false;
  bool get hasPipedWater => _hasPipedWater;

  String? _electricityAccess;
  String? get electricityAccess => _electricityAccess;

  String? _sewageDisposal;
  String? get sewageDisposal => _sewageDisposal;

  String? _wasteCollection;
  String? get wasteCollection => _wasteCollection;

  String? _accessibilityLevel;
  String? get accessibilityLevel => _accessibilityLevel;

  bool _isInGeographicRiskArea = false;
  bool get isInGeographicRiskArea => _isInGeographicRiskArea;

  bool _hasDifficultAccess = false;
  bool get hasDifficultAccess => _hasDifficultAccess;

  bool _isInSocialConflictArea = false;
  bool get isInSocialConflictArea => _isInSocialConflictArea;

  bool _hasDiagnosticObservations = false;
  bool get hasDiagnosticObservations => _hasDiagnosticObservations;

  // ── Original state for dirty checking ──────────────────────

  String? _originalType;
  String? _originalWallMaterial;
  int _originalNumberOfRooms = 0;
  int _originalNumberOfBedrooms = 0;
  int _originalNumberOfBathrooms = 0;
  String? _originalWaterSupply;
  bool _originalHasPipedWater = false;
  String? _originalElectricityAccess;
  String? _originalSewageDisposal;
  String? _originalWasteCollection;
  String? _originalAccessibilityLevel;
  bool _originalIsInGeographicRiskArea = false;
  bool _originalHasDifficultAccess = false;
  bool _originalIsInSocialConflictArea = false;
  bool _originalHasDiagnosticObservations = false;

  bool get hasData => _type != null;

  bool get canSave =>
      _type != null &&
      _wallMaterial != null &&
      _waterSupply != null &&
      _electricityAccess != null &&
      _sewageDisposal != null &&
      _wasteCollection != null &&
      _accessibilityLevel != null &&
      _isDirty;

  bool get _isDirty =>
      _type != _originalType ||
      _wallMaterial != _originalWallMaterial ||
      _numberOfRooms != _originalNumberOfRooms ||
      _numberOfBedrooms != _originalNumberOfBedrooms ||
      _numberOfBathrooms != _originalNumberOfBathrooms ||
      _waterSupply != _originalWaterSupply ||
      _hasPipedWater != _originalHasPipedWater ||
      _electricityAccess != _originalElectricityAccess ||
      _sewageDisposal != _originalSewageDisposal ||
      _wasteCollection != _originalWasteCollection ||
      _accessibilityLevel != _originalAccessibilityLevel ||
      _isInGeographicRiskArea != _originalIsInGeographicRiskArea ||
      _hasDifficultAccess != _originalHasDifficultAccess ||
      _isInSocialConflictArea != _originalIsInSocialConflictArea ||
      _hasDiagnosticObservations != _originalHasDiagnosticObservations;

  // ── Actions ────────────────────────────────────────────────

  void updateType(String value) {
    _type = value;
    notifyListeners();
  }

  void updateWallMaterial(String value) {
    _wallMaterial = value;
    notifyListeners();
  }

  void updateNumberOfRooms(int value) {
    _numberOfRooms = value;
    notifyListeners();
  }

  void updateNumberOfBedrooms(int value) {
    _numberOfBedrooms = value;
    notifyListeners();
  }

  void updateNumberOfBathrooms(int value) {
    _numberOfBathrooms = value;
    notifyListeners();
  }

  void updateWaterSupply(String value) {
    _waterSupply = value;
    notifyListeners();
  }

  void toggleHasPipedWater() {
    _hasPipedWater = !_hasPipedWater;
    notifyListeners();
  }

  void updateElectricityAccess(String value) {
    _electricityAccess = value;
    notifyListeners();
  }

  void updateSewageDisposal(String value) {
    _sewageDisposal = value;
    notifyListeners();
  }

  void updateWasteCollection(String value) {
    _wasteCollection = value;
    notifyListeners();
  }

  void updateAccessibilityLevel(String value) {
    _accessibilityLevel = value;
    notifyListeners();
  }

  void toggleGeographicRisk() {
    _isInGeographicRiskArea = !_isInGeographicRiskArea;
    notifyListeners();
  }

  void toggleDifficultAccess() {
    _hasDifficultAccess = !_hasDifficultAccess;
    notifyListeners();
  }

  void toggleSocialConflict() {
    _isInSocialConflictArea = !_isInSocialConflictArea;
    notifyListeners();
  }

  void toggleDiagnosticObservations() {
    _hasDiagnosticObservations = !_hasDiagnosticObservations;
    notifyListeners();
  }

  // ── Load ───────────────────────────────────────────────────

  Future<Result<void>> _load() async {
    _log.info('Loading patient: $patientId');
    final result = await _getPatientUseCase.execute(patientId);

    switch (result) {
      case Success(:final value):
        final pd = value.personalData;
        final first = pd?.firstName ?? '';
        final last = pd?.lastName ?? '';
        _patientName = '$first $last'.trim();

        final housing = value.housingCondition;
        if (housing != null) {
          _type = housing.type.name;
          _wallMaterial = housing.wallMaterial.name;
          _numberOfRooms = housing.numberOfRooms;
          _numberOfBedrooms = housing.numberOfBedrooms;
          _numberOfBathrooms = housing.numberOfBathrooms;
          _waterSupply = housing.waterSupply.name;
          _hasPipedWater = housing.hasPipedWater;
          _electricityAccess = housing.electricityAccess.name;
          _sewageDisposal = housing.sewageDisposal.name;
          _wasteCollection = housing.wasteCollection.name;
          _accessibilityLevel = housing.accessibilityLevel.name;
          _isInGeographicRiskArea = housing.isInGeographicRiskArea;
          _hasDifficultAccess = housing.hasDifficultAccess;
          _isInSocialConflictArea = housing.isInSocialConflictArea;
          _hasDiagnosticObservations = housing.hasDiagnosticObservations;

          _saveOriginals();
        }
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

    final detail = HousingConditionDetail(
      type: _type!,
      wallMaterial: _wallMaterial!,
      numberOfRooms: _numberOfRooms,
      numberOfBedrooms: _numberOfBedrooms,
      numberOfBathrooms: _numberOfBathrooms,
      waterSupply: _waterSupply!,
      hasPipedWater: _hasPipedWater,
      electricityAccess: _electricityAccess!,
      sewageDisposal: _sewageDisposal!,
      wasteCollection: _wasteCollection!,
      accessibilityLevel: _accessibilityLevel!,
      isInGeographicRiskArea: _isInGeographicRiskArea,
      hasDifficultAccess: _hasDifficultAccess,
      isInSocialConflictArea: _isInSocialConflictArea,
      hasDiagnosticObservations: _hasDiagnosticObservations,
    );

    final PatientId patId;
    switch (PatientId.create(patientId)) {
      case Success(:final value):
        patId = value;
      case Failure(:final error):
        return Failure(error);
    }

    final intent = HousingConditionDetailMapper.toIntent(
      detail,
      patientId: patId,
    );

    final result = await _updateHousingConditionUseCase.execute(intent);
    if (result.isSuccess) {
      _saveOriginals();
      notifyListeners();
    }
    return result;
  }

  // ── Helpers ────────────────────────────────────────────────

  void _saveOriginals() {
    _originalType = _type;
    _originalWallMaterial = _wallMaterial;
    _originalNumberOfRooms = _numberOfRooms;
    _originalNumberOfBedrooms = _numberOfBedrooms;
    _originalNumberOfBathrooms = _numberOfBathrooms;
    _originalWaterSupply = _waterSupply;
    _originalHasPipedWater = _hasPipedWater;
    _originalElectricityAccess = _electricityAccess;
    _originalSewageDisposal = _sewageDisposal;
    _originalWasteCollection = _wasteCollection;
    _originalAccessibilityLevel = _accessibilityLevel;
    _originalIsInGeographicRiskArea = _isInGeographicRiskArea;
    _originalHasDifficultAccess = _hasDifficultAccess;
    _originalIsInSocialConflictArea = _isInSocialConflictArea;
    _originalHasDiagnosticObservations = _hasDiagnosticObservations;
  }

  @override
  void onDispose() {
    _log.info('Disposing HousingConditionViewModel');
    loadCommand.dispose();
    saveCommand.dispose();
  }
}
