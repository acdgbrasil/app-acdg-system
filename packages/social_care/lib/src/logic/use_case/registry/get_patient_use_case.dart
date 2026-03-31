import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../../data/repositories/patient_repository.dart';

/// Retrieves a patient by their [PatientId].
class GetPatientUseCase extends BaseUseCase<PatientId, Patient> {
  GetPatientUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<Patient>> execute(PatientId id) {
    return _patientRepository.getPatient(id);
  }
}
