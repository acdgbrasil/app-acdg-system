import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/assessment_intents.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../mappers/assessment_mapper.dart';

/// UseCase to update social health summary.
class UpdateSocialHealthSummaryUseCase
    extends BaseUseCase<UpdateSocialHealthSummaryIntent, void> {
  UpdateSocialHealthSummaryUseCase({
    required PatientRepository patientRepository,
  }) : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<void>> execute(UpdateSocialHealthSummaryIntent intent) async {
    final domainRes = AssessmentMapper.toSocialHealthSummary(intent);
    if (domainRes case Failure(:final error)) return Failure(error);

    return _patientRepository.updateSocialHealthSummary(
      intent.patientId,
      (domainRes as Success<SocialHealthSummary>).value,
    );
  }
}
