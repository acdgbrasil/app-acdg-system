import 'package:core/core.dart';
import 'package:social_care/social_care.dart';
import 'package:social_care/src/ui/home/models/patient_detail_translator.dart';
import 'package:social_care/src/ui/home/models/patient_summary.dart';
import 'package:social_care/src/ui/home/view/components/detail_panel_state.dart';
import 'package:social_care/src/ui/home/view/components/home_form_state.dart';

class HomeViewModel extends BaseViewModel {
  HomeViewModel({
    required ListPatientsUseCase listPatientsUseCase,
    required GetPatientUseCase getPatientUseCase,
  }) : _listPatientsUseCase = listPatientsUseCase,
       _getPatientUseCase = getPatientUseCase {
    load = Command0<List<PatientSummary>>(_loadPatients);
    select = Command1<void, String>(_selectPatient);
  }

  final ListPatientsUseCase _listPatientsUseCase;
  final GetPatientUseCase _getPatientUseCase;

  // ── Commands ─────────────────────────────────────────────────
  late final Command0<List<PatientSummary>> load;
  late final Command1<void, String> select;

  // ── UI State ──────────────────────────────────────────────────
  String _activeTab = 'familias';
  String get activeTab => _activeTab;

  void setActiveTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void onSearchChanged() => notifyListeners();

  // ── FormsHolds ───────────────────────────────────────────────
  final homeFormState = HomeFormState();
  final detailPanelState = DetailPanelState();

  // ── Load patients ────────────────────────────────────────────
  Future<Result<List<PatientSummary>>> _loadPatients() async {
    final result = await _listPatientsUseCase.execute();
    if (result case Success(:final value)) {
      homeFormState.families.value = value;
    }
    return result;
  }

  // ── Select patient (detail on-demand) ────────────────────────
  Future<Result<void>> _selectPatient(String patientId) async {
    detailPanelState.selectPatient(patientId);

    if (detailPanelState.selectedPatientId.value == null) {
      return const Success(null);
    }

    // UseCase now handles String -> PatientId conversion and returns ResultBundle
    final result = await _getPatientUseCase.execute(patientId);

    if (detailPanelState.selectedPatientId.value != patientId) {
      return const Success(null);
    }

    if (result case Success(value: final patient)) {
      final detailResult = PatientDetailTranslator.toDetailResult(patient);
      detailPanelState.patientDetail.value = detailResult.patientDetail;
      detailPanelState.fichas.value = detailResult.fichas;
      return const Success(null);
    }

    return Failure((result as Failure).error);
  }

  // ── Delegate panel actions ───────────────────────────────────
  void closePanel() => detailPanelState.closePanel();
  void showFichas() => detailPanelState.showFichas();
  void showDados() => detailPanelState.showDados();

  // ── Dispose ──────────────────────────────────────────────────
  @override
  void dispose() {
    load.dispose();
    select.dispose();
    homeFormState.dispose();
    detailPanelState.dispose();
    super.dispose();
  }
}
