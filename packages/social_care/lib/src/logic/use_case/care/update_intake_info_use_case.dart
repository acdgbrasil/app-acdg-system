import 'package:core/core.dart';
import '../../../data/commands/intervention_intents.dart';
import '../../../data/repositories/patient_repository.dart';

/// UseCase to update intake information.
class UpdateIntakeInfoUseCase
    extends BaseUseCase<UpdateIntakeInfoIntent, void> {
  UpdateIntakeInfoUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<void>> execute(UpdateIntakeInfoIntent intent) {
    return _patientRepository.updateIntakeInfo(intent.patientId, intent.info);
  }
}
