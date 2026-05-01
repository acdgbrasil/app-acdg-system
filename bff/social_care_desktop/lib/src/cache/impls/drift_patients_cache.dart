import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../use_cases/_shared/clock.dart';
import '../_shared/cache_database.dart';
import '../_shared/cached.dart';
import '../_shared/failures.dart';
import '../contracts/patients_cache.dart';
import '../daos/patient_dao.dart';

/// Drift-backed implementation of [PatientsCache].
///
/// Thin `Result` wrapper over [PatientDao]. Try/catch is permitted at
/// this boundary only — every raw exception becomes a typed
/// `Failure(CacheFailure(...))`. Missing rows are `Success(null)`,
/// never `Failure`.
///
/// The constructor eagerly fires a no-op `SELECT 1` to force Drift's
/// `ensureOpen` (which runs `MigrationStrategy.onCreate`, including
/// FTS5 trigger creation) BEFORE the caller can interleave a
/// `database.close()`. Without this warm-up, closing a never-opened
/// Drift DB silently re-opens on the next query (Drift quirk for
/// lazy-init), so DB-failure paths would surface as `Success(null)`
/// instead of `Failure`. The warm-up is awaited at the start of every
/// public method.
class DriftPatientsCache implements PatientsCache {
  DriftPatientsCache(CacheDatabase db, {Clock? clock})
    : _dao = PatientDao(db),
      _clock = clock ?? const SystemClock(),
      _ready = db.customSelect('SELECT 1').get();

  final PatientDao _dao;
  final Clock _clock;
  final Future<Object?> _ready;

  @override
  Future<Result<Cached<PatientResponse>?>> findById(String patientId) async {
    try {
      await _ready;
      final row = await _dao.findPatientById(patientId);
      if (row == null) return const Success(null);
      return Success(
        Cached(
          dto: PatientResponse.fromJson(
            jsonDecode(row.payload) as Map<String, dynamic>,
          ),
          cachedAt: row.cachedAt,
          version: row.version,
        ),
      );
    } catch (e, st) {
      return Failure<Cached<PatientResponse>?>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<Cached<PatientResponse>?>> findByPersonId(
    String personId,
  ) async {
    try {
      await _ready;
      final row = await _dao.findPatientByPersonId(personId);
      if (row == null) return const Success(null);
      return Success(
        Cached(
          dto: PatientResponse.fromJson(
            jsonDecode(row.payload) as Map<String, dynamic>,
          ),
          cachedAt: row.cachedAt,
          version: row.version,
        ),
      );
    } catch (e, st) {
      return Failure<Cached<PatientResponse>?>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<List<PatientSummaryResponse>>> listSummaries({
    String? status,
    String? cursor,
    int? limit,
  }) async {
    try {
      await _ready;
      final rows = await _dao.listSummaries(status: status, limit: limit);
      return Success(
        rows
            .map(
              (r) => PatientSummaryResponse.fromJson(
                jsonDecode(r.payload) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
    } catch (e, st) {
      return Failure<List<PatientSummaryResponse>>(
        CacheFailure(e),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<List<PatientSummaryResponse>>> searchSummaries(
    String term,
  ) async {
    try {
      await _ready;
      final rows = await _dao.searchSummaries(term);
      return Success(
        rows
            .map(
              (r) => PatientSummaryResponse.fromJson(
                jsonDecode(r.payload) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
    } catch (e, st) {
      return Failure<List<PatientSummaryResponse>>(
        CacheFailure(e),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> upsertPatient(
    PatientResponse dto, {
    required int version,
  }) async {
    try {
      await _ready;
      await _dao.upsertPatient(
        id: dto.patientId,
        personId: dto.personId,
        status: dto.status,
        payload: jsonEncode(dto.toJson()),
        cachedAt: _clock.now(),
        version: version,
      );
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> upsertSummary(
    PatientSummaryResponse dto, {
    required int version,
  }) async {
    try {
      await _ready;
      await _dao.upsertSummary(
        patientId: dto.patientId,
        personId: dto.personId,
        firstName: dto.firstName,
        lastName: dto.lastName,
        primaryDiagnosis: dto.primaryDiagnosis,
        status: dto.status,
        payload: jsonEncode(dto.toJson()),
        cachedAt: _clock.now(),
        version: version,
      );
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> deletePatient(String patientId) async {
    try {
      await _ready;
      await _dao.deletePatientById(patientId);
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> deleteSummary(String patientId) async {
    try {
      await _ready;
      await _dao.deleteSummaryById(patientId);
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> clear() async {
    try {
      await _ready;
      await _dao.clearPatients();
      await _dao.clearSummaries();
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }
}
