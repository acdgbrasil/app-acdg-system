import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../cache/contracts/audit_cache.dart';
import '../_shared/clock.dart';

/// Pattern 1 — cache-first audit trail read with optional eventType /
/// limit / offset filters; falls back to remote `getAuditTrail` on
/// cache miss and upserts each entry.
class FetchAuditTrailUseCase {
  FetchAuditTrailUseCase({
    required AuditCache cache,
    required AuditContract remote,
    required Clock clock,
    Duration staleAfter = const Duration(minutes: 5),
  }) : _cache = cache,
       _remote = remote;

  final AuditCache _cache;
  final AuditContract _remote;

  Future<Result<List<AuditTrailEntryResponse>>> call(
    String patientId, {
    String? eventType,
    int? limit,
    int? offset,
  }) async {
    final cachedResult = await _cache.listByPatient(
      patientId,
      eventType: eventType,
      limit: limit,
      offset: offset,
    );
    if (cachedResult case Success(:final value) when value.isNotEmpty) {
      return Success<List<AuditTrailEntryResponse>>(value);
    }
    final fresh = await _remote.getAuditTrail(
      patientId,
      eventType: eventType,
      limit: limit,
      offset: offset,
    );
    switch (fresh) {
      case Success(:final value):
        for (final entry in value.data) {
          await _cache.upsert(patientId, entry, version: 1);
        }
        return Success<List<AuditTrailEntryResponse>>(value.data);
      case Failure(:final error, :final stackTrace):
        return Failure<List<AuditTrailEntryResponse>>(
          error,
          stackTrace: stackTrace,
        );
    }
  }
}
