import 'package:core/core.dart';
import '../../../data/commands/intervention_intents.dart';
import '../../../data/repositories/patient_repository.dart';

/// UseCase to update institutional placement history.
class UpdatePlacementHistoryUseCase
    extends BaseUseCase<UpdatePlacementHistoryIntent, void> {
  UpdatePlacementHistoryUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<void>> execute(UpdatePlacementHistoryIntent intent) {
    return _patientRepository.updatePlacementHistory(
      intent.patientId,
      intent.history,
    );
  }
}
