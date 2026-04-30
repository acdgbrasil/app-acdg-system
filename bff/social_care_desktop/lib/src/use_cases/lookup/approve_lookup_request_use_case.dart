import 'dart:async';

import 'package:core_contracts/core_contracts.dart';
import 'package:uuid/uuid.dart';

import '../../cache/contracts/lookup_cache.dart';
import '../../sync/engine/sync_engine.dart';
import '../../sync/outbox/outbox_repository.dart';
import '../../sync/outbox/sync_mutation.dart';
import '../_shared/clock.dart';
import '../_shared/use_case_failures.dart';

/// Pattern 2 — body-less write. Reads the cached request to derive
/// `expectedVersion`; payload is `{}`.
class ApproveLookupRequestUseCase {
  ApproveLookupRequestUseCase({
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

  Future<Result<void>> call(String requestId) async {
    final cachedResult = await _cache.findRequestById(requestId);
    switch (cachedResult) {
      case Failure(:final error, :final stackTrace):
        return Failure<void>(error, stackTrace: stackTrace);
      case Success(:final value):
        if (value == null) {
          return Failure<void>(
            NotFoundFailure('Lookup request $requestId not in cache'),
          );
        }
        final mutation = ApproveLookupRequestMutation(
          id: _uuid.v4(),
          aggregateId: requestId,
          expectedVersion: value.version,
          createdAt: _clock.now(),
        );
        final enqueue = await _outbox.enqueue(mutation);
        switch (enqueue) {
          case Failure(:final error, :final stackTrace):
            return Failure<void>(error, stackTrace: stackTrace);
          case Success():
            await _cache.upsertRequest(value.dto, version: value.version + 1);
            unawaited(_engine.triggerDrain());
            return const Success<void>(null);
        }
    }
  }
}
