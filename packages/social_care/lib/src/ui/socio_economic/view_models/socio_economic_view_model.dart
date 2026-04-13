import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../../data/commands/assessment_intents.dart';
import '../../../logic/use_case/assessment/update_socio_economic_use_case.dart';
import '../../../logic/use_case/registry/get_patient_use_case.dart';

class BenefitRow {
  String benefitName;
  double amount;
  String? beneficiaryId;
  BenefitRow({this.benefitName = '', this.amount = 0, this.beneficiaryId});
}

class MemberOption {
  final String id;
  final String label;
  const MemberOption({required this.id, required this.label});
}

class SocioEconomicViewModel extends BaseViewModel {
  SocioEconomicViewModel({
    required this.patientId,
    required GetPatientUseCase getPatientUseCase,
    required UpdateSocioEconomicUseCase updateSocioEconomicUseCase,
  }) : _getPatientUseCase = getPatientUseCase,
       _updateSocioEconomicUseCase = updateSocioEconomicUseCase {
    loadCommand = Command0<void>(_load);
    saveCommand = Command0<void>(_save);
  }

  final String patientId;
  final GetPatientUseCase _getPatientUseCase;
  final UpdateSocioEconomicUseCase _updateSocioEconomicUseCase;

  late final Command0<void> loadCommand;
  late final Command0<void> saveCommand;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  String _patientName = '';
  String get patientName => _patientName;

  List<MemberOption> _familyMembers = [];
  List<MemberOption> get familyMembers => _familyMembers;

  double _totalFamilyIncome = 0;
  double get totalFamilyIncome => _totalFamilyIncome;
  double _incomePerCapita = 0;
  double get incomePerCapita => _incomePerCapita;
  bool _receivesSocialBenefit = false;
  bool get receivesSocialBenefit => _receivesSocialBenefit;
  String _mainSourceOfIncome = '';
  String get mainSourceOfIncome => _mainSourceOfIncome;
  bool _hasUnemployed = false;
  bool get hasUnemployed => _hasUnemployed;
  List<BenefitRow> _socialBenefits = [];
  List<BenefitRow> get socialBenefits => _socialBenefits;

  double _origTotalIncome = 0;
  double _origPerCapita = 0;
  bool _origReceivesBenefit = false;
  String _origMainSource = '';
  bool _origHasUnemployed = false;
  int _origBenefitsCount = 0;
  bool _hasLoadedData = false;

  bool get hasData => _hasLoadedData;

  bool get canSave =>
      _totalFamilyIncome >= 0 &&
      _incomePerCapita >= 0 &&
      _incomePerCapita <= _totalFamilyIncome &&
      _mainSourceOfIncome.trim().isNotEmpty &&
      (!_receivesSocialBenefit || _socialBenefits.isNotEmpty) &&
      (_receivesSocialBenefit || _socialBenefits.isEmpty) &&
      _isDirty;

  bool get _isDirty =>
      _totalFamilyIncome != _origTotalIncome ||
      _incomePerCapita != _origPerCapita ||
      _receivesSocialBenefit != _origReceivesBenefit ||
      _mainSourceOfIncome != _origMainSource ||
      _hasUnemployed != _origHasUnemployed ||
      _socialBenefits.length != _origBenefitsCount;

  void updateTotalIncome(double v) { _totalFamilyIncome = v; notifyListeners(); }
  void updatePerCapita(double v) { _incomePerCapita = v; notifyListeners(); }
  void toggleReceivesBenefit() { _receivesSocialBenefit = !_receivesSocialBenefit; notifyListeners(); }
  void updateMainSource(String v) { _mainSourceOfIncome = v; notifyListeners(); }
  void toggleHasUnemployed() { _hasUnemployed = !_hasUnemployed; notifyListeners(); }

  void addBenefit() { _socialBenefits = [..._socialBenefits, BenefitRow()]; notifyListeners(); }
  void removeBenefit(int i) { _socialBenefits = List.of(_socialBenefits)..removeAt(i); notifyListeners(); }
  void updateBenefitName(int i, String v) { _socialBenefits[i].benefitName = v; notifyListeners(); }
  void updateBenefitAmount(int i, double v) { _socialBenefits[i].amount = v; notifyListeners(); }
  void updateBenefitBeneficiary(int i, String v) { _socialBenefits[i].beneficiaryId = v; notifyListeners(); }

  Future<Result<void>> _load() async {
    final result = await _getPatientUseCase.execute(patientId);
    switch (result) {
      case Success(:final value):
        final pd = value.personalData;
        _patientName = '${pd?.firstName ?? ''} ${pd?.lastName ?? ''}'.trim();
        final members = <MemberOption>[MemberOption(id: value.personId.value, label: _patientName.isNotEmpty ? _patientName : 'Pessoa de referencia')];
        for (final m in value.familyMembers) { members.add(MemberOption(id: m.personId.value, label: m.fullName ?? 'Membro')); }
        _familyMembers = members;

        final ses = value.socioeconomicSituation;
        if (ses != null) {
          _totalFamilyIncome = ses.totalFamilyIncome;
          _incomePerCapita = ses.incomePerCapita;
          _receivesSocialBenefit = ses.receivesSocialBenefit;
          _mainSourceOfIncome = ses.mainSourceOfIncome;
          _hasUnemployed = ses.hasUnemployed;
          _socialBenefits = ses.socialBenefits.items.map((b) => BenefitRow(benefitName: b.benefitName, amount: b.amount, beneficiaryId: b.beneficiaryId.value)).toList();
          _saveOriginals();
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
    switch (PatientId.create(patientId)) { case Success(:final value): patId = value; case Failure(:final error): return Failure(error); }

    final benefits = <SocialBenefit>[];
    for (final b in _socialBenefits) {
      if (b.benefitName.isEmpty || b.beneficiaryId == null) continue;
      final PersonId bid;
      switch (PersonId.create(b.beneficiaryId!)) { case Success(:final value): bid = value; case Failure(:final error): return Failure(error); }
      // benefitTypeId defaults to a placeholder lookup — the backend resolves it
      final LookupId typeId; switch (LookupId.create('00000000-0000-0000-0000-000000000000')) { case Success(:final value): typeId = value; case Failure(:final error): return Failure(error); }
      final sbResult = SocialBenefit.create(benefitName: b.benefitName, benefitTypeId: typeId, amount: b.amount, beneficiaryId: bid);
      if (sbResult case Success(:final value)) benefits.add(value);
      if (sbResult case Failure(:final error)) return Failure(error);
    }

    final intent = UpdateSocioEconomicIntent(patientId: patId, totalFamilyIncome: _totalFamilyIncome, incomePerCapita: _incomePerCapita, receivesSocialBenefit: _receivesSocialBenefit, socialBenefits: benefits, mainSourceOfIncome: _mainSourceOfIncome.trim(), hasUnemployed: _hasUnemployed);
    final result = await _updateSocioEconomicUseCase.execute(intent);
    if (result.isSuccess) { _saveOriginals(); notifyListeners(); }
    return result;
  }

  void _saveOriginals() {
    _origTotalIncome = _totalFamilyIncome; _origPerCapita = _incomePerCapita;
    _origReceivesBenefit = _receivesSocialBenefit; _origMainSource = _mainSourceOfIncome;
    _origHasUnemployed = _hasUnemployed; _origBenefitsCount = _socialBenefits.length;
  }

  @override
  void onDispose() { loadCommand.dispose(); saveCommand.dispose(); }
}
