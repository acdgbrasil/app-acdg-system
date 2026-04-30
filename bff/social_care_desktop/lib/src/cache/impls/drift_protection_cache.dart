import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../_shared/cache_database.dart';
import '../_shared/failures.dart';
import '../contracts/protection_cache.dart';
import '../daos/protection_dao.dart';

/// Drift-backed implementation of [ProtectionCache].
///
/// See [DriftPatientsCache] for the rationale behind the `_ready`
/// warm-up future awaited at the start of every method.
class DriftProtectionCache implements ProtectionCache {
  DriftProtectionCache(CacheDatabase db)
    : _dao = ProtectionDao(db),
      _ready = db.customSelect('SELECT 1').get();

  final ProtectionDao _dao;
  final Future<Object?> _ready;

  // ── Referrals ────────────────────────────────────────────────────────
  @override
  Future<Result<ReferralResponse?>> findReferralById(
    String patientId,
    String referralId,
  ) async {
    try {
      await _ready;
      final row = await _dao.findReferralById(patientId, referralId);
      if (row == null) return const Success(null);
      return Success(
        ReferralResponse.fromJson(
          jsonDecode(row.payload) as Map<String, dynamic>,
        ),
      );
    } catch (e, st) {
      return Failure<ReferralResponse?>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<List<ReferralResponse>>> listReferrals(String patientId) async {
    try {
      await _ready;
      final rows = await _dao.listReferrals(patientId);
      return Success(
        rows
            .map(
              (r) => ReferralResponse.fromJson(
                jsonDecode(r.payload) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
    } catch (e, st) {
      return Failure<List<ReferralResponse>>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> upsertReferral(
    String patientId,
    ReferralResponse dto, {
    required int version,
  }) async {
    try {
      await _ready;
      await _dao.upsertReferral(
        patientId: patientId,
        id: dto.id,
        payload: jsonEncode(dto.toJson()),
        cachedAt: DateTime.now(),
        version: version,
      );
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> deleteReferral(
    String patientId,
    String referralId,
  ) async {
    try {
      await _ready;
      await _dao.deleteReferral(patientId, referralId);
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }

  // ── ViolationReports ─────────────────────────────────────────────────
  @override
  Future<Result<ViolationReportResponse?>> findViolationReportById(
    String patientId,
    String reportId,
  ) async {
    try {
      await _ready;
      final row = await _dao.findViolationReportById(patientId, reportId);
      if (row == null) return const Success(null);
      return Success(
        ViolationReportResponse.fromJson(
          jsonDecode(row.payload) as Map<String, dynamic>,
        ),
      );
    } catch (e, st) {
      return Failure<ViolationReportResponse?>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<List<ViolationReportResponse>>> listViolationReports(
    String patientId,
  ) async {
    try {
      await _ready;
      final rows = await _dao.listViolationReports(patientId);
      return Success(
        rows
            .map(
              (r) => ViolationReportResponse.fromJson(
                jsonDecode(r.payload) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
    } catch (e, st) {
      return Failure<List<ViolationReportResponse>>(
        CacheFailure(e),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> upsertViolationReport(
    String patientId,
    ViolationReportResponse dto, {
    required int version,
  }) async {
    try {
      await _ready;
      await _dao.upsertViolationReport(
        patientId: patientId,
        id: dto.id,
        payload: jsonEncode(dto.toJson()),
        cachedAt: DateTime.now(),
        version: version,
      );
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> deleteViolationReport(
    String patientId,
    String reportId,
  ) async {
    try {
      await _ready;
      await _dao.deleteViolationReport(patientId, reportId);
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }

  // ── PlacementHistory ─────────────────────────────────────────────────
  @override
  Future<Result<PlacementHistoryResponse?>> findPlacementHistory(
    String patientId,
  ) async {
    try {
      await _ready;
      final row = await _dao.findPlacementHistory(patientId);
      if (row == null) return const Success(null);
      return Success(
        PlacementHistoryResponse.fromJson(
          jsonDecode(row.payload) as Map<String, dynamic>,
        ),
      );
    } catch (e, st) {
      return Failure<PlacementHistoryResponse?>(
        CacheFailure(e),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> upsertPlacementHistory(
    String patientId,
    PlacementHistoryResponse dto, {
    required int version,
  }) async {
    try {
      await _ready;
      await _dao.upsertPlacementHistory(
        patientId: patientId,
        payload: jsonEncode(dto.toJson()),
        cachedAt: DateTime.now(),
        version: version,
      );
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> deletePlacementHistory(String patientId) async {
    try {
      await _ready;
      await _dao.deletePlacementHistory(patientId);
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }

  // ── Cross-cutting ────────────────────────────────────────────────────
  @override
  Future<Result<void>> clear() async {
    try {
      await _ready;
      await _dao.clearReferrals();
      await _dao.clearViolationReports();
      await _dao.clearPlacementHistories();
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }
}
