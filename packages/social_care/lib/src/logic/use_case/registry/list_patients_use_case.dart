import 'package:core/core.dart';
import 'package:social_care/src/data/repositories/patient_repository.dart';
import 'package:social_care/src/ui/home/models/patient_summary.dart';

/// Orchestrates patient listing.
///
/// The repository already returns typed [PatientSummary] data.
/// This use case serves as the single entry point for the UI layer,
/// and can be extended with cross-cutting concerns (e.g. sorting,
/// filtering, analytics) without changing the ViewModel.
class ListPatientsUseCase extends NoInputUseCase<List<PatientSummary>> {
  ListPatientsUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<List<PatientSummary>>> execute() {
    return _patientRepository.listPatients();
  }
}
