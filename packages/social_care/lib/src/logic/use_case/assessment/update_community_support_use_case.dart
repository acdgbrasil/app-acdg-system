import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/assessment_intents.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../mappers/assessment_mapper.dart';

/// UseCase to update community support network.
class UpdateCommunitySupportUseCase
    extends BaseUseCase<UpdateCommunitySupportIntent, void> {
  UpdateCommunitySupportUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<void>> execute(UpdateCommunitySupportIntent intent) async {
    final domainRes = AssessmentMapper.toCommunitySupport(intent);
    if (domainRes case Failure(:final error)) return Failure(error);

    return _patientRepository.updateCommunitySupportNetwork(
      intent.patientId,
      (domainRes as Success<CommunitySupportNetwork>).value,
    );
  }
}
