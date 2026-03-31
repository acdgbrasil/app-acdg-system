import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';
import 'package:social_care/src/logic/use_case/registry/list_patients_use_case.dart';
import 'package:social_care/src/ui/home/models/ficha_status.dart';
import 'package:social_care/src/ui/home/models/patient_detail.dart';
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
    load.execute();
  }

  final ListPatientsUseCase _listPatientsUseCase;
  final GetPatientUseCase _getPatientUseCase;

  // ── Commands ─────────────────────────────────────────────────
  late final Command0<List<PatientSummary>> load;
  late final Command1<void, String> select;

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

    final id = PatientId.create(patientId);
    if (id.isFailure) return const Success(null);

    final result = await _getPatientUseCase.execute(id.valueOrNull!);

    if (detailPanelState.selectedPatientId.value != patientId) {
      return const Success(null);
    }

    if (result case Success(:final value)) {
      detailPanelState.patientDetail.value =
          PatientDetail.fromPatient(value);
      detailPanelState.fichas.value = FichaStatus.fromPatient(value);
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
