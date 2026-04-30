import 'dart:async';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../cache/contracts/lookup_cache.dart';
import '../../sync/engine/sync_engine.dart';
import '../../sync/outbox/outbox_repository.dart';
import '../../sync/outbox/sync_mutation.dart';
import '../_shared/clock.dart';
import '../_shared/use_case_failures.dart';

/// Pattern 2 — patient-style update on lookup item id. `expectedVersion`
/// read from cache, `tableName` persisted in payload as `_tableName`.
class UpdateLookupItemUseCase {
  UpdateLookupItemUseCase({
    required LookupCache cache,
    required OutboxRepository outbox,
    required SyncEngine engine,
    required Clock clock,
    Uuid? uuid,
  }) : _cache = cache,
       _outbox = outbox,
       _engine = engine,
       _clock = clock,
       _uuid = uuid ?? const Uuid();

  final LookupCache _cache;
  final OutboxRepository _outbox;
  final SyncEngine _engine;
  final Clock _clock;
  final Uuid _uuid;

  Future<Result<void>> call(
    String tableName,
    String itemId,
    UpdateLookupItemRequest req,
  ) async {
    final cachedResult = await _cache.findItemById(tableName, itemId);
    switch (cachedResult) {
      case Failure(:final error, :final stackTrace):
        return Failure<void>(error, stackTrace: stackTrace);
      case Success(:final value):
        if (value == null) {
          return Failure<void>(
            NotFoundFailure('Lookup item $itemId not in cache'),
          );
        }
        final mutation = UpdateLookupItemMutation(
          id: _uuid.v4(),
          aggregateId: itemId,
          expectedVersion: value.version,
          createdAt: _clock.now(),
          tableName: tableName,
          request: req,
        );
        final enqueue = await _outbox.enqueue(mutation);
        switch (enqueue) {
          case Failure(:final error, :final stackTrace):
            return Failure<void>(error, stackTrace: stackTrace);
          case Success():
            await _cache.upsertItem(
              tableName,
              value.dto,
              version: value.version + 1,
            );
            unawaited(_engine.triggerDrain());
            return const Success<void>(null);
        }
    }
  }
}
