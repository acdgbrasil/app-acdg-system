import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../../data/commands/assessment_intents.dart';
import '../../../data/repositories/lookup_repository.dart';
import '../../../logic/use_case/assessment/update_work_and_income_use_case.dart';
import '../../../logic/use_case/registry/get_patient_use_case.dart';

class IncomeRow { String? memberId; String? occupationId; bool hasWorkCard; double monthlyAmount; IncomeRow({this.memberId, this.occupationId, this.hasWorkCard = false, this.monthlyAmount = 0}); }
class BenefitRow { String benefitName; double amount; String? beneficiaryId; BenefitRow({this.benefitName = '', this.amount = 0, this.beneficiaryId}); }
class MemberOption { final String id; final String label; const MemberOption({required this.id, required this.label}); }

class WorkAndIncomeViewModel extends BaseViewModel {
  WorkAndIncomeViewModel({
    required this.patientId,
    required GetPatientUseCase getPatientUseCase,
    required UpdateWorkAndIncomeUseCase updateWorkAndIncomeUseCase,
    required LookupRepository lookupRepository,
  }) : _getPatientUseCase = getPatientUseCase,
       _updateWorkAndIncomeUseCase = updateWorkAndIncomeUseCase,
       _lookupRepository = lookupRepository {
    loadCommand = Command0<void>(_load);
    saveCommand = Command0<void>(_save);
    _loadLookups();
  }

  final String patientId;
  final GetPatientUseCase _getPatientUseCase;
  final UpdateWorkAndIncomeUseCase _updateWorkAndIncomeUseCase;
  final LookupRepository _lookupRepository;

  late final Command0<void> loadCommand;
  late final Command0<void> saveCommand;

  String? _errorMessage; String? get errorMessage => _errorMessage;
  String _patientName = ''; String get patientName => _patientName;

  List<LookupItem> _occupationLookup = []; List<LookupItem> get occupationLookup => _occupationLookup;
  List<MemberOption> _familyMembers = []; List<MemberOption> get familyMembers => _familyMembers;

  List<IncomeRow> _individualIncomes = []; List<IncomeRow> get individualIncomes => _individualIncomes;
  List<BenefitRow> _socialBenefits = []; List<BenefitRow> get socialBenefits => _socialBenefits;
  bool _hasRetiredMembers = false; bool get hasRetiredMembers => _hasRetiredMembers;

  int _origIncomeCount = 0; int _origBenefitCount = 0; bool _origRetired = false; bool _hasLoadedData = false;
  bool get hasData => _hasLoadedData;
  bool get canSave => _isDirty;
  bool get _isDirty => _individualIncomes.length != _origIncomeCount || _socialBenefits.length != _origBenefitCount || _hasRetiredMembers != _origRetired || _individualIncomes.isNotEmpty || _socialBenefits.isNotEmpty;

  void addIncome() { _individualIncomes = [..._individualIncomes, IncomeRow()]; notifyListeners(); }
  void removeIncome(int i) { _individualIncomes = List.of(_individualIncomes)..removeAt(i); notifyListeners(); }
  void updateIncomeMember(int i, String v) { _individualIncomes[i].memberId = v; notifyListeners(); }
  void updateIncomeOccupation(int i, String v) { _individualIncomes[i].occupationId = v; notifyListeners(); }
  void toggleIncomeWorkCard(int i) { _individualIncomes[i].hasWorkCard = !_individualIncomes[i].hasWorkCard; notifyListeners(); }
  void updateIncomeAmount(int i, double v) { _individualIncomes[i].monthlyAmount = v; notifyListeners(); }

  void addBenefit() { _socialBenefits = [..._socialBenefits, BenefitRow()]; notifyListeners(); }
  void removeBenefit(int i) { _socialBenefits = List.of(_socialBenefits)..removeAt(i); notifyListeners(); }
  void updateBenefitName(int i, String v) { _socialBenefits[i].benefitName = v; notifyListeners(); }
  void updateBenefitAmount(int i, double v) { _socialBenefits[i].amount = v; notifyListeners(); }
  void updateBenefitBeneficiary(int i, String v) { _socialBenefits[i].beneficiaryId = v; notifyListeners(); }

  void toggleRetired() { _hasRetiredMembers = !_hasRetiredMembers; notifyListeners(); }

  Future<void> _loadLookups() async {
    final r = await _lookupRepository.getLookupTable('dominio_ocupacao');
    if (r case Success(:final value)) _occupationLookup = value;
    notifyListeners();
  }

  Future<Result<void>> _load() async {
    final result = await _getPatientUseCase.execute(patientId);
    switch (result) {
      case Success(:final value):
        final pd = value.personalData;
        _patientName = '${pd?.firstName ?? ''} ${pd?.lastName ?? ''}'.trim();
        final members = <MemberOption>[MemberOption(id: value.personId.value, label: _patientName.isNotEmpty ? _patientName : 'Pessoa de referencia')];
        for (final m in value.familyMembers) members.add(MemberOption(id: m.personId.value, label: m.fullName ?? 'Membro'));
        _familyMembers = members;

        final wi = value.workAndIncome;
        if (wi != null) {
          _individualIncomes = wi.individualIncomes.map((inc) => IncomeRow(memberId: inc.memberId.value, occupationId: inc.occupationId.value, hasWorkCard: inc.hasWorkCard, monthlyAmount: inc.monthlyAmount)).toList();
          _socialBenefits = wi.socialBenefits.map((b) => BenefitRow(benefitName: b.benefitName, amount: b.amount, beneficiaryId: b.beneficiaryId.value)).toList();
          _hasRetiredMembers = wi.hasRetiredMembers;
          _origIncomeCount = _individualIncomes.length; _origBenefitCount = _socialBenefits.length; _origRetired = _hasRetiredMembers;
        }
        _hasLoadedData = true;
      case Failure(:final error): _errorMessage = 'Falha ao carregar paciente';
    }
    notifyListeners(); return const Success(null);
  }

  Future<Result<void>> _save() async {
    if (!canSave) return const Success(null);
    final PatientId patId; switch (PatientId.create(patientId)) { case Success(:final value): patId = value; case Failure(:final error): return Failure(error); }

    final incomes = <WorkIncomeVO>[];
    for (final inc in _individualIncomes) {
      if (inc.memberId == null || inc.occupationId == null) continue;
      final PersonId mid; switch (PersonId.create(inc.memberId!)) { case Success(:final value): mid = value; case Failure(:final error): return Failure(error); }
      final LookupId oid; switch (LookupId.create(inc.occupationId!)) { case Success(:final value): oid = value; case Failure(:final error): return Failure(error); }
      final wiResult = WorkIncomeVO.create(memberId: mid, occupationId: oid, hasWorkCard: inc.hasWorkCard, monthlyAmount: inc.monthlyAmount);
      if (wiResult case Success(:final value)) incomes.add(value);
      if (wiResult case Failure(:final error)) return Failure(error);
    }

    final benefits = <SocialBenefit>[];
    for (final b in _socialBenefits) {
      if (b.benefitName.isEmpty || b.beneficiaryId == null) continue;
      final PersonId bid; switch (PersonId.create(b.beneficiaryId!)) { case Success(:final value): bid = value; case Failure(:final error): return Failure(error); }
      final LookupId typeId; switch (LookupId.create('00000000-0000-0000-0000-000000000000')) { case Success(:final value): typeId = value; case Failure(:final error): return Failure(error); }
      final sbr = SocialBenefit.create(benefitName: b.benefitName, benefitTypeId: typeId, amount: b.amount, beneficiaryId: bid);
      if (sbr case Success(:final value)) benefits.add(value);
      if (sbr case Failure(:final error)) return Failure(error);
    }

    final intent = UpdateWorkAndIncomeIntent(patientId: patId, individualIncomes: incomes, socialBenefits: benefits, hasRetiredMembers: _hasRetiredMembers);
    final result = await _updateWorkAndIncomeUseCase.execute(intent);
    if (result.isSuccess) { _origIncomeCount = _individualIncomes.length; _origBenefitCount = _socialBenefits.length; _origRetired = _hasRetiredMembers; notifyListeners(); }
    return result;
  }

  @override
  void onDispose() { loadCommand.dispose(); saveCommand.dispose(); }
}
