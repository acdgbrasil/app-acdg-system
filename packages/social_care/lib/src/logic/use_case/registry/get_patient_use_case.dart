import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../../data/repositories/patient_repository.dart';
import '../../../ui/home/models/patient_detail_result.dart';

/// Retrieves a patient detail by their unique string ID.
///
/// Encapsulates the conversion from [String] to domain [PatientId]
/// and returns a bundled [PatientDetailResult] for the UI.
class GetPatientUseCase extends BaseUseCase<String, PatientDetailResult> {
  GetPatientUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<PatientDetailResult>> execute(String patientId) async {
    final idResult = PatientId.create(patientId);

    return switch (idResult) {
      Success(value: final id) => _patientRepository.getPatient(id),
      Failure(:final error) => Failure(error),
    };
  }
}
