import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../../data/repositories/patient_repository.dart';

/// Intent to fetch audit trail for a patient.
final class GetAuditTrailIntent with Equatable {
  const GetAuditTrailIntent({required this.patientId, this.eventType});

  final PatientId patientId;
  final String? eventType;

  @override
  List<Object?> get props => [patientId, eventType];
}

/// UseCase to fetch the audit trail for a specific patient.
class GetAuditTrailUseCase
    extends BaseUseCase<GetAuditTrailIntent, List<AuditEvent>> {
  GetAuditTrailUseCase({required PatientRepository patientRepository})
    : _patientRepository = patientRepository;

  final PatientRepository _patientRepository;

  @override
  Future<Result<List<AuditEvent>>> execute(GetAuditTrailIntent intent) {
    return _patientRepository.getAuditTrail(
      intent.patientId,
      eventType: intent.eventType,
    );
  }
}
