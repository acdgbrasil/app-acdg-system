import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/assessment_intents.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../mappers/assessment_mapper.dart';

/// UseCase to update socioeconomic situation.
class UpdateSocioEconomicUseCase
    extends BaseUseCase<UpdateSocioEconomicIntent, void> {
  UpdateSocioEconomicUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<void>> execute(UpdateSocioEconomicIntent intent) async {
    final domainRes = AssessmentMapper.toSocioEconomic(intent);
    if (domainRes case Failure(:final error)) return Failure(error);

    return _patientRepository.updateSocioEconomicSituation(
      intent.patientId,
      (domainRes as Success<SocioEconomicSituation>).value,
    );
  }
}
