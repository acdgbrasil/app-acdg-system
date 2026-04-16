import 'package:core_contracts/core_contracts.dart';

import '../dto/responses/audit/audit_trail_entry_response.dart';
import '../dto/shared/standard_response.dart';

/// Audit contract — audit trail for patient events.
abstract interface class AuditContract {
  /// Retrieves the audit trail for a specific patient.
  ///
  /// Supports offset-based pagination via [limit] and [offset].
  /// Optionally filtered by [eventType].
  Future<Result<StandardResponse<List<AuditTrailEntryResponse>>>> getAuditTrail(
    String patientId, {
    String? eventType,
    int? limit,
    int? offset,
  });
}
