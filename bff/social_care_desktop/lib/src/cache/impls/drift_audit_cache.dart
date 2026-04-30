import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../_shared/cache_database.dart';
import '../_shared/failures.dart';
import '../contracts/audit_cache.dart';
import '../daos/audit_dao.dart';

/// Drift-backed implementation of [AuditCache].
///
/// See [DriftPatientsCache] for the rationale behind the `_ready`
/// warm-up future awaited at the start of every method.
class DriftAuditCache implements AuditCache {
  DriftAuditCache(CacheDatabase db, {DateTime Function()? now})
    : _dao = AuditDao(db),
      _now = now ?? DateTime.now,
      _ready = db.customSelect('SELECT 1').get();

  final AuditDao _dao;
  final DateTime Function() _now;
  final Future<Object?> _ready;

  @override
  Future<Result<AuditTrailEntryResponse?>> findById(String entryId) async {
    try {
      await _ready;
      final row = await _dao.findById(entryId);
      if (row == null) return const Success(null);
      return Success(
        AuditTrailEntryResponse.fromJson(
          jsonDecode(row.payload) as Map<String, dynamic>,
        ),
      );
    } catch (e, st) {
      return Failure<AuditTrailEntryResponse?>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<List<AuditTrailEntryResponse>>> listByPatient(
    String patientId, {
    String? eventType,
    int? limit,
    int? offset,
  }) async {
    try {
      await _ready;
      final rows = await _dao.listByPatient(
        patientId,
        eventType: eventType,
        limit: limit,
        offset: offset,
      );
      return Success(
        rows
            .map(
              (r) => AuditTrailEntryResponse.fromJson(
                jsonDecode(r.payload) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
    } catch (e, st) {
      return Failure<List<AuditTrailEntryResponse>>(
        CacheFailure(e),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> upsert(
    String patientId,
    AuditTrailEntryResponse dto, {
    required int version,
  }) async {
    try {
      await _ready;
      await _dao.upsert(
        id: dto.id,
        patientId: patientId,
        eventType: dto.eventType,
        payload: jsonEncode(dto.toJson()),
        cachedAt: _now(),
        version: version,
      );
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> delete(String entryId) async {
    try {
      await _ready;
      await _dao.deleteById(entryId);
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> clear() async {
    try {
      await _ready;
      await _dao.clearAll();
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }
}
