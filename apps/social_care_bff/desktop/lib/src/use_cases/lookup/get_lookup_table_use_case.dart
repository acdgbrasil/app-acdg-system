import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../cache/contracts/lookup_cache.dart';
import '../_shared/clock.dart';
import '../_shared/stale_policy.dart';

/// Pattern 1 — cache-first by `tableName`. Stale heuristic uses the
/// freshest row's `cachedAt` as a proxy for the table's freshness;
/// when the cache is stale OR empty, the remote `getLookupTable` is
/// consulted and every returned item is upserted.
class GetLookupTableUseCase {
  GetLookupTableUseCase({
    required LookupCache cache,
    required LookupContract remote,
    required Clock clock,
    Duration staleAfter = const Duration(minutes: 5),
  }) : _cache = cache,
       _remote = remote,
       _clock = clock,
       _stale = StalePolicy(staleAfter: staleAfter);

  final LookupCache _cache;
  final LookupContract _remote;
  final Clock _clock;
  final StalePolicy _stale;

  Future<Result<List<LookupItemResponse>>> call(String tableName) async {
    final cachedResult = await _cache.listItems(tableName);
    if (cachedResult case Success(:final value) when value.isNotEmpty) {
      // Use the first item's metadata as a freshness proxy. We need a
      // `cachedAt` to compute staleness; reading the metadata of any
      // single item via `findItemById` keeps the surface narrow.
      final firstItemResult = await _cache.findItemById(
        tableName,
        value.first.id,
      );
      if (firstItemResult case Success(value: final cached?)) {
        if (!_stale.isStale(cached.cachedAt, now: _clock.now())) {
          return Success<List<LookupItemResponse>>(value);
        }
      }
    }
    final fresh = await _remote.getLookupTable(tableName);
    switch (fresh) {
      case Success(:final value):
        for (final item in value.data) {
          await _cache.upsertItem(tableName, item, version: 1);
        }
        return Success<List<LookupItemResponse>>(value.data);
      case Failure(:final error, :final stackTrace):
        return Failure<List<LookupItemResponse>>(error, stackTrace: stackTrace);
    }
  }
}
