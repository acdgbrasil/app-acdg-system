import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/assessment_intents.dart';
import '../../../data/mappers/educational_status_mapper.dart';
import '../../../data/repositories/patient_repository.dart';

/// UseCase to update educational status.
class UpdateEducationalStatusUseCase
    extends BaseUseCase<UpdateEducationalStatusIntent, void> {
  UpdateEducationalStatusUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<void>> execute(UpdateEducationalStatusIntent intent) async {
    final domainRes = EducationalStatusMapper.toEducationalStatus(intent);
    if (domainRes case Failure(:final error)) return Failure(error);

    return _patientRepository.updateEducationalStatus(
      intent.patientId,
      (domainRes as Success<EducationalStatus>).value,
    );
  }
}
