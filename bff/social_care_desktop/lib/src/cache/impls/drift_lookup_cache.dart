import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../_shared/cache_database.dart';
import '../_shared/cached.dart';
import '../_shared/failures.dart';
import '../contracts/lookup_cache.dart';
import '../daos/lookup_dao.dart';

/// Drift-backed implementation of [LookupCache].
///
/// See [DriftPatientsCache] for the rationale behind the `_ready`
/// warm-up future awaited at the start of every method.
class DriftLookupCache implements LookupCache {
  DriftLookupCache(CacheDatabase db, {DateTime Function()? now})
    : _dao = LookupDao(db),
      _now = now ?? DateTime.now,
      _ready = db.customSelect('SELECT 1').get();

  final LookupDao _dao;
  final DateTime Function() _now;
  final Future<Object?> _ready;

  // ── Items ────────────────────────────────────────────────────────────
  @override
  Future<Result<Cached<LookupItemResponse>?>> findItemById(
    String tableName,
    String itemId,
  ) async {
    try {
      await _ready;
      final row = await _dao.findItemById(tableName, itemId);
      if (row == null) return const Success(null);
      return Success(
        Cached(
          dto: LookupItemResponse.fromJson(
            jsonDecode(row.payload) as Map<String, dynamic>,
          ),
          cachedAt: row.cachedAt,
          version: row.version,
        ),
      );
    } catch (e, st) {
      return Failure<Cached<LookupItemResponse>?>(
        CacheFailure(e),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<List<LookupItemResponse>>> listItems(String tableName) async {
    try {
      await _ready;
      final rows = await _dao.listItems(tableName);
      return Success(
        rows
            .map(
              (r) => LookupItemResponse.fromJson(
                jsonDecode(r.payload) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
    } catch (e, st) {
      return Failure<List<LookupItemResponse>>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<List<String>>> listAllTables() async {
    try {
      await _ready;
      final names = await _dao.listAllTableNames();
      return Success(names);
    } catch (e, st) {
      return Failure<List<String>>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<List<String>>> searchTables(String term) async {
    try {
      await _ready;
      final names = await _dao.searchTableNames(term);
      return Success(names);
    } catch (e, st) {
      return Failure<List<String>>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> upsertItem(
    String tableName,
    LookupItemResponse dto, {
    required int version,
  }) async {
    try {
      await _ready;
      await _dao.upsertItem(
        tableName: tableName,
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
  Future<Result<void>> deleteItem(String tableName, String itemId) async {
    try {
      await _ready;
      await _dao.deleteItem(tableName, itemId);
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }

  @override
  Future<Result<void>> clearTable(String tableName) async {
    try {
      await _ready;
      await _dao.clearItemsByTable(tableName);
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }

  // ── Requests ─────────────────────────────────────────────────────────
  @override
  Future<Result<Cached<LookupRequestResponse>?>> findRequestById(
    String requestId,
  ) async {
    try {
      await _ready;
      final row = await _dao.findRequestById(requestId);
      if (row == null) return const Success(null);
      return Success(
        Cached(
          dto: LookupRequestResponse.fromJson(
            jsonDecode(row.payload) as Map<String, dynamic>,
          ),
          cachedAt: row.cachedAt,
          version: row.version,
        ),
      );
    } catch (e, st) {
      return Failure<Cached<LookupRequestResponse>?>(
        CacheFailure(e),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<List<LookupRequestResponse>>> listRequests({
    String? status,
    String? tableName,
    int? limit,
  }) async {
    try {
      await _ready;
      final rows = await _dao.listRequests(
        status: status,
        tableName: tableName,
        limit: limit,
      );
      return Success(
        rows
            .map(
              (r) => LookupRequestResponse.fromJson(
                jsonDecode(r.payload) as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
    } catch (e, st) {
      return Failure<List<LookupRequestResponse>>(
        CacheFailure(e),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> upsertRequest(
    LookupRequestResponse dto, {
    required int version,
  }) async {
    try {
      await _ready;
      await _dao.upsertRequest(
        id: dto.id,
        tableName: dto.tableName,
        status: dto.status,
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
  Future<Result<void>> deleteRequest(String requestId) async {
    try {
      await _ready;
      await _dao.deleteRequest(requestId);
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
      await _dao.clearItems();
      await _dao.clearRequests();
      return const Success(null);
    } catch (e, st) {
      return Failure<void>(CacheFailure(e), stackTrace: st);
    }
  }
}
