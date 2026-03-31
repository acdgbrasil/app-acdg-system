import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/commands/intervention_intents.dart';
import '../../../data/repositories/patient_repository.dart';
import '../../mappers/intervention_mapper.dart';

/// UseCase to report a rights violation.
class ReportViolationUseCase
    extends BaseUseCase<ReportViolationIntent, ViolationReportId> {
  ReportViolationUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<ViolationReportId>> execute(
    ReportViolationIntent intent,
  ) async {
    final domainRes = InterventionMapper.toViolationReport(intent);
    if (domainRes case Failure(:final error)) return Failure(error);

    return _patientRepository.reportViolation(
      intent.patientId,
      (domainRes as Success<RightsViolationReport>).value,
    );
  }
}
