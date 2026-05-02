import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../composition/builders/audit_use_cases.dart';

/// Audit sub-facade — 1 thin pass-through method over the Audit use
/// case (A18b-v2).
///
/// Backed by [AuditUseCases] — a data class grouping the 1 use case (D02).
class AuditFacade {
  AuditFacade.internal({required AuditUseCases useCases})
    : _useCases = useCases;

  final AuditUseCases _useCases;

  Future<Result<List<AuditTrailEntryResponse>>> fetchAuditTrail(
    String patientId, {
    String? eventType,
    int? limit,
    int? offset,
  }) => _useCases.fetchAuditTrail(
    patientId,
    eventType: eventType,
    limit: limit,
    offset: offset,
  );
}
