import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '_shared/remote_base.dart';

/// Audit trail remote — `GET /api/v1/patients/{patientId}/audit-trail`.
class AuditRemote extends RemoteBase implements AuditContract {
  AuditRemote({required super.dio});

  @override
  Future<Result<StandardResponse<List<AuditTrailEntryResponse>>>> getAuditTrail(
    String patientId, {
    String? eventType,
    int? limit,
    int? offset,
  }) async {
    try {
      final params = <String, dynamic>{
        'eventType': ?eventType,
        'limit': ?limit,
        'offset': ?offset,
      };
      final response = await dio.get<Map<String, dynamic>>(
        '/api/v1/patients/$patientId/audit-trail',
        queryParameters: params.isEmpty ? null : params,
        options: RemoteBase.passthroughStatus,
      );
      if (response.statusCode == 200) {
        final data = response.data!['data'] as List<dynamic>;
        // T1.3: long audit trails (>50 entries) delegate to a background
        // isolate per Concurrency Policy §C1. Patients with multi-year
        // histories routinely surpass the threshold; mapping inline
        // would freeze the UI while the auditor scrolls. AuditTrail
        // EntryResponse.fromJson is a static-method tear-off → sendable.
        final mapped = await RemoteBase.mapListPossiblyInIsolate(
          data,
          AuditTrailEntryResponse.fromJson,
        );
        return Success<StandardResponse<List<AuditTrailEntryResponse>>>(
          wrapResponse(mapped),
        );
      }
      return backendFailure(response, 'Failed to fetch audit trail');
    } catch (e, stackTrace) {
      return Failure<StandardResponse<List<AuditTrailEntryResponse>>>(
        e,
        stackTrace: stackTrace,
      );
    }
  }
}
