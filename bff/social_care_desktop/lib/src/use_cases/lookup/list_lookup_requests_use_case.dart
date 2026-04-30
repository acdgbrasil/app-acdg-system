import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../cache/contracts/lookup_cache.dart';
import '../_shared/clock.dart';

/// Pattern 1 — cache-first list of governance requests with optional
/// filters. Falls back to remote `getLookupRequests` when the cache
/// returns empty.
class ListLookupRequestsUseCase {
  ListLookupRequestsUseCase({
    required LookupCache cache,
    required LookupContract remote,
    required Clock clock,
    Duration staleAfter = const Duration(minutes: 5),
  }) : _cache = cache,
       _remote = remote;

  final LookupCache _cache;
  final LookupContract _remote;

  Future<Result<List<LookupRequestResponse>>> call({
    String? status,
    String? tableName,
    int? limit,
  }) async {
    final cachedResult = await _cache.listRequests(
      status: status,
      tableName: tableName,
      limit: limit,
    );
    if (cachedResult case Success(:final value) when value.isNotEmpty) {
      return Success<List<LookupRequestResponse>>(value);
    }
    final fresh = await _remote.getLookupRequests();
    switch (fresh) {
      case Success(:final value):
        for (final request in value.data) {
          await _cache.upsertRequest(request, version: 1);
        }
        // Re-query cache so the returned list honors the filters.
        final after = await _cache.listRequests(
          status: status,
          tableName: tableName,
          limit: limit,
        );
        if (after case Success(:final value)) {
          return Success<List<LookupRequestResponse>>(value);
        }
        return Success<List<LookupRequestResponse>>(value.data);
      case Failure(:final error, :final stackTrace):
        return Failure<List<LookupRequestResponse>>(
          error,
          stackTrace: stackTrace,
        );
    }
  }
}
