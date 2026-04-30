import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../_shared/cache_database.dart';
import '../_shared/failures.dart';
import '../contracts/care_cache.dart';
import '../daos/care_dao.dart';

/// Drift-backed implementation of [CareCache].
///
/// See [DriftPatientsCache] for the rationale behind the `_ready`
/// warm-up future awaited at the start of every method.
class DriftCareCache implements CareCache {
  DriftCareCache(CacheDatabase db, {DateTime Function()? now})
    : _dao = CareDao(db),
      _now = now ?? DateTime.now,
      _ready = db.customSelect('SELECT 1').get();

  final CareDao _dao;
  final DateTime Function() _now;
  final Future<Object?> _ready;

  @override
  Future<Result<AppointmentResponse?>> findById(
    String patientId,
    String appointmentId,
  ) async {
    try {
      await _ready;
      final row = await _dao.findById(patientId, appointmentId);
      if (row == null) return const Success(null);
      return Success(
        AppointmentResponse.fromJson(
          jsonDecode(row.payload) as Map<String, dynamic>,
        ),
      );
    } catch (e, st) {
      return Failure<AppointmentResponse?>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<List<AppointmentResponse>>> listByPatient(
    String patientId, {
    int? limit,
  }) async {
    try {
      await _ready;
      final rows = await _dao.listByPatient(patientId, limit: limit);
      return Success(
        rows
            .map(
              (r) => AppointmentResponse.fromJson(
                jsonDecode(r.payload) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
    } catch (e, st) {
      return Failure<List<AppointmentResponse>>(
        CacheFailure(e),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> upsert(
    String patientId,
    AppointmentResponse dto, {
    required int version,
  }) async {
    try {
      await _ready;
      await _dao.upsert(
        patientId: patientId,
        id: dto.id,
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
  Future<Result<void>> delete(String patientId, String appointmentId) async {
    try {
      await _ready;
      await _dao.deleteById(patientId, appointmentId);
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
