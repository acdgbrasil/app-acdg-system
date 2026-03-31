import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/assessment_intents.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../mappers/assessment_mapper.dart';

/// UseCase to update housing condition.
class UpdateHousingConditionUseCase
    extends BaseUseCase<UpdateHousingConditionIntent, void> {
  UpdateHousingConditionUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<void>> execute(UpdateHousingConditionIntent intent) async {
    final domainRes = AssessmentMapper.toHousingCondition(intent);
    if (domainRes case Failure(:final error)) return Failure(error);

    return _patientRepository.updateHousingCondition(
      intent.patientId,
      (domainRes as Success<HousingCondition>).value,
    );
  }
}
