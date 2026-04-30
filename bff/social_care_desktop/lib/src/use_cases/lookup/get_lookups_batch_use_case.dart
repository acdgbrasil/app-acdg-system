import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../cache/contracts/lookup_cache.dart';
import '../_shared/clock.dart';
import 'get_lookup_table_use_case.dart';

/// Fan-out over [GetLookupTableUseCase]. Returns a map keyed by
/// `tableName`; tables with cache-miss fall back to the remote per the
/// inner use case.
class GetLookupsBatchUseCase {
  GetLookupsBatchUseCase({
    required LookupCache cache,
    required LookupContract remote,
    required Clock clock,
    Duration staleAfter = const Duration(minutes: 5),
  }) : _cache = cache,
       _remote = remote,
       _clock = clock,
       _staleAfter = staleAfter;

  final LookupCache _cache;
  final LookupContract _remote;
  final Clock _clock;
  final Duration _staleAfter;

  Future<Result<Map<String, List<LookupItemResponse>>>> call(
    List<String> tables,
  ) async {
    if (tables.isEmpty) {
      return const Success<Map<String, List<LookupItemResponse>>>(
        <String, List<LookupItemResponse>>{},
      );
    }
    final out = <String, List<LookupItemResponse>>{};
    for (final tableName in tables) {
      final inner = GetLookupTableUseCase(
        cache: _cache,
        remote: _remote,
        clock: _clock,
        staleAfter: _staleAfter,
      );
      final result = await inner(tableName);
      switch (result) {
        case Success(:final value):
          out[tableName] = value;
        case Failure(:final error, :final stackTrace):
          return Failure<Map<String, List<LookupItemResponse>>>(
            error,
            stackTrace: stackTrace,
          );
      }
    }
    return Success<Map<String, List<LookupItemResponse>>>(out);
  }
}
