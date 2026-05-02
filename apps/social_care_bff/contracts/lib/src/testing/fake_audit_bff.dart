import 'package:core_contracts/core_contracts.dart';

import '../contract/dto/responses/audit/audit_trail_entry_response.dart';
import '../contract/dto/shared/standard_response.dart';
import '../contract/sub_contracts/audit_contract.dart';

/// In-memory fake for [AuditContract].
///
/// Keeps an in-memory audit trail per `patientId`. Empty by default;
/// tests can pre-seed entries via [seed] or write directly to [trails].
///
/// The trail map is a simple data container — per the encapsulation policy
/// it is exposed as a public field rather than hidden behind `_`.
class FakeAuditBff implements AuditContract {
  FakeAuditBff();

  /// Audit trail entries keyed by `patientId`.
  final Map<String, List<AuditTrailEntryResponse>> trails = {};

  /// Seeds audit entries for a given patient (used by tests only).
  void seed(String patientId, List<AuditTrailEntryResponse> entries) {
    trails[patientId] = List<AuditTrailEntryResponse>.from(entries);
  }

  StandardResponse<T> _wrap<T>(T data) => StandardResponse(
    data: data,
    meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
  );

  @override
  Future<Result<StandardResponse<List<AuditTrailEntryResponse>>>> getAuditTrail(
    String patientId, {
    String? eventType,
    int? limit,
    int? offset,
  }) async {
    final entries = List<AuditTrailEntryResponse>.from(
      trails[patientId] ?? const <AuditTrailEntryResponse>[],
    );
    return Success(_wrap(entries));
  }
}
