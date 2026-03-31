import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/intervention_intents.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../mappers/intervention_mapper.dart';

/// UseCase to create a new referral.
class CreateReferralUseCase
    extends BaseUseCase<CreateReferralIntent, ReferralId> {
  CreateReferralUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<ReferralId>> execute(CreateReferralIntent intent) async {
    final domainRes = InterventionMapper.toReferral(intent);
    if (domainRes case Failure(:final error)) return Failure(error);

    return _patientRepository.createReferral(
      intent.patientId,
      (domainRes as Success<Referral>).value,
    );
  }
}
