import 'package:core/core.dart';
import '../../../data/commands/family_intents.dart';
import '../../../data/repositories/patient_repository.dart';

/// Orchestrates removing a family member from a patient record.
class RemoveFamilyMemberUseCase
    extends BaseUseCase<RemoveFamilyMemberIntent, void> {
  RemoveFamilyMemberUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<void>> execute(RemoveFamilyMemberIntent intent) {
    return _patientRepository.removeFamilyMember(
      intent.patientId,
      intent.memberPersonId,
    );
  }
}
