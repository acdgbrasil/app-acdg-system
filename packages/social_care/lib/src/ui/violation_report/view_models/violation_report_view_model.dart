import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../../data/commands/intervention_intents.dart';
import '../../../logic/use_case/protection/report_violation_use_case.dart';
import '../../../logic/use_case/registry/get_patient_use_case.dart';

class MemberOption { final String id; final String label; const MemberOption({required this.id, required this.label}); }

class ViolationReportViewModel extends BaseViewModel {
  ViolationReportViewModel({
    required this.patientId,
    required GetPatientUseCase getPatientUseCase,
    required ReportViolationUseCase reportViolationUseCase,
  }) : _getPatientUseCase = getPatientUseCase,
       _reportViolationUseCase = reportViolationUseCase {
    loadCommand = Command0<void>(_load);
    saveCommand = Command0<void>(_save);
  }

  final String patientId;
  final GetPatientUseCase _getPatientUseCase;
  final ReportViolationUseCase _reportViolationUseCase;

  late final Command0<void> loadCommand;
  late final Command0<void> saveCommand;

  String? _errorMessage; String? get errorMessage => _errorMessage;
  String _patientName = ''; String get patientName => _patientName;
  List<MemberOption> _familyMembers = []; List<MemberOption> get familyMembers => _familyMembers;

  String _reportDate = DateTime.now().toIso8601String().substring(0, 10);
  String get reportDate => _reportDate;
  String _incidentDate = '';
  String get incidentDate => _incidentDate;
  String? _victimId; String? get victimId => _victimId;
  String? _violationType; String? get violationType => _violationType;
  String _descriptionOfFact = ''; String get descriptionOfFact => _descriptionOfFact;
  String _actionsTaken = ''; String get actionsTaken => _actionsTaken;

  bool _hasLoadedData = false;
  bool get hasData => _hasLoadedData;
  bool _saved = false;
  bool get saved => _saved;

  bool get canSave =>
      _reportDate.isNotEmpty &&
      _victimId != null &&
      _violationType != null &&
      _descriptionOfFact.trim().isNotEmpty &&
      _descriptionOfFact.length <= 5000 &&
      _actionsTaken.length <= 5000 &&
      _validateDates();

  bool _validateDates() {
    final report = DateTime.tryParse(_reportDate);
    if (report == null) return false;
    if (report.isAfter(DateTime.now().add(const Duration(days: 1)))) return false;
    if (_incidentDate.isNotEmpty) {
      final incident = DateTime.tryParse(_incidentDate);
      if (incident == null) return false;
      if (incident.isAfter(report)) return false;
    }
    return true;
  }

  void updateReportDate(String v) { _reportDate = v; notifyListeners(); }
  void updateIncidentDate(String v) { _incidentDate = v; notifyListeners(); }
  void updateVictim(String v) { _victimId = v; notifyListeners(); }
  void updateViolationType(String v) { _violationType = v; notifyListeners(); }
  void updateDescription(String v) { _descriptionOfFact = v; notifyListeners(); }
  void updateActions(String v) { _actionsTaken = v; notifyListeners(); }

  Future<Result<void>> _load() async {
    final result = await _getPatientUseCase.execute(patientId);
    switch (result) {
      case Success(:final value):
        final pd = value.personalData;
        _patientName = '${pd?.firstName ?? ''} ${pd?.lastName ?? ''}'.trim();
        final members = <MemberOption>[MemberOption(id: value.personId.value, label: _patientName.isNotEmpty ? _patientName : 'Pessoa de referencia')];
        for (final m in value.familyMembers) members.add(MemberOption(id: m.personId.value, label: m.fullName ?? 'Membro'));
        _familyMembers = members;
        _hasLoadedData = true;
      case Failure(:final error): _errorMessage = 'Falha ao carregar paciente';
    }
    notifyListeners(); return const Success(null);
  }

  Future<Result<void>> _save() async {
    if (!canSave) return const Success(null);
    final PatientId patId; switch (PatientId.create(patientId)) { case Success(:final value): patId = value; case Failure(:final error): return Failure(error); }
    DateTime? incDate;
    if (_incidentDate.isNotEmpty) { incDate = DateTime.tryParse(_incidentDate); }

    final intent = ReportViolationIntent(patientId: patId, victimId: _victimId!, violationType: ViolationType.values.byName(_violationType!), descriptionOfFact: _descriptionOfFact.trim(), incidentDate: incDate, actionsTaken: _actionsTaken.trim().isEmpty ? null : _actionsTaken.trim());
    final result = await _reportViolationUseCase.execute(intent);
    if (result.isSuccess) { _saved = true; _clearForm(); notifyListeners(); }
    return result;
  }

  void _clearForm() {
    _reportDate = DateTime.now().toIso8601String().substring(0, 10);
    _incidentDate = ''; _victimId = null; _violationType = null;
    _descriptionOfFact = ''; _actionsTaken = '';
  }

  @override
  void onDispose() { loadCommand.dispose(); saveCommand.dispose(); }
}
