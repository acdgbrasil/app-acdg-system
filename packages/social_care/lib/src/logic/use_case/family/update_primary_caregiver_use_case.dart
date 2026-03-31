import 'package:core/core.dart';
import '../../../data/commands/family_intents.dart';
import '../../../data/repositories/patient_repository.dart';

/// Orchestrates assigning a primary caregiver for a patient.
class UpdatePrimaryCaregiverUseCase
    extends BaseUseCase<UpdatePrimaryCaregiverIntent, void> {
  UpdatePrimaryCaregiverUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<void>> execute(UpdatePrimaryCaregiverIntent intent) {
    return _patientRepository.assignPrimaryCaregiver(
      intent.patientId,
      intent.memberPersonId,
    );
  }
}
