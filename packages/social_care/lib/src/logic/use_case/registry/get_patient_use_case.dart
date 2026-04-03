import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../../data/repositories/patient_repository.dart';

/// Retrieves a patient by their unique string ID.
///
/// Encapsulates the conversion from [String] to domain [PatientId]
/// and delegates to the repository.
class GetPatientUseCase extends BaseUseCase<String, Patient> {
  GetPatientUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<Patient>> execute(String patientId) async {
    final idResult = PatientId.create(patientId);

    return switch (idResult) {
      Success(value: final id) => _patientRepository.getPatient(id),
      Failure(:final error) => Failure(error),
    };
  }
}
