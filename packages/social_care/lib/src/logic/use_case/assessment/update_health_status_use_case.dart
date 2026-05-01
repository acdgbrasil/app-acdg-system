import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/assessment_intents.dart';
import '../../../data/mappers/health_status_mapper.dart';
import '../../../data/repositories/patient_repository.dart';

/// UseCase to update health status.
class UpdateHealthStatusUseCase
    extends BaseUseCase<UpdateHealthStatusIntent, void> {
  UpdateHealthStatusUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<void>> execute(UpdateHealthStatusIntent intent) async {
    final domainRes = HealthStatusMapper.toHealthStatus(intent);
    if (domainRes case Failure(:final error)) return Failure(error);

    return _patientRepository.updateHealthStatus(
      intent.patientId,
      (domainRes as Success<HealthStatus>).value,
    );
  }
}
