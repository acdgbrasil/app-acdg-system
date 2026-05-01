import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../use_cases/audit/fetch_audit_trail_use_case.dart';

/// Audit sub-facade — 1 thin pass-through method over the Audit use
/// case (A18b-v2).
class AuditFacade {
  AuditFacade.internal({required FetchAuditTrailUseCase fetchAuditTrail})
    : _fetchAuditTrail = fetchAuditTrail;

  final FetchAuditTrailUseCase _fetchAuditTrail;

  Future<Result<List<AuditTrailEntryResponse>>> fetchAuditTrail(
    String patientId, {
    String? eventType,
    int? limit,
    int? offset,
  }) => _fetchAuditTrail(
    patientId,
    eventType: eventType,
    limit: limit,
    offset: offset,
  );
}
