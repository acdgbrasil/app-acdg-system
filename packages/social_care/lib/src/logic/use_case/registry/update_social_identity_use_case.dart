import 'package:core/core.dart';
import '../../../data/commands/registry_intents.dart';
import '../../../data/repositories/patient_repository.dart';

/// UseCase to update social identity.
class UpdateSocialIdentityUseCase
    extends BaseUseCase<UpdateSocialIdentityIntent, void> {
  UpdateSocialIdentityUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<void>> execute(UpdateSocialIdentityIntent intent) {
    return _patientRepository.updateSocialIdentity(
      intent.patientId,
      intent.identity,
    );
  }
}
