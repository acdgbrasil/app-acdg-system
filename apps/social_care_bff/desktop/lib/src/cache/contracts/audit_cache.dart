import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

/// Desktop-only Read Model for audit trail entries scoped to a patient.
/// Filtering by `eventType` is supported via a B-Tree index;
/// `limit`/`offset` provide pagination.
abstract interface class AuditCache {
  Future<Result<AuditTrailEntryResponse?>> findById(String entryId);

  Future<Result<List<AuditTrailEntryResponse>>> listByPatient(
    String patientId, {
    String? eventType,
    int? limit,
    int? offset,
  });

  Future<Result<void>> upsert(
    String patientId,
    AuditTrailEntryResponse dto, {
    required int version,
  });

  Future<Result<void>> delete(String entryId);

  Future<Result<void>> clear();
}
