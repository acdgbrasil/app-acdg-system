import 'dart:async';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../sync/engine/sync_engine.dart';
import '../../sync/outbox/outbox_repository.dart';
import '../../sync/outbox/sync_mutation.dart';
import '../_shared/clock.dart';

/// Pattern 2 — register-style write. `tableName` rides in the
/// payload's `_tableName` key; backend-generated id arrives async via
/// drain.
class CreateLookupItemUseCase {
  CreateLookupItemUseCase({
    required OutboxRepository outbox,
    required SyncEngine engine,
    required Clock clock,
    Uuid? uuid,
  }) : _outbox = outbox,
       _engine = engine,
       _clock = clock,
       _uuid = uuid ?? const Uuid();

  final OutboxRepository _outbox;
  final SyncEngine _engine;
  final Clock _clock;
  final Uuid _uuid;

  Future<Result<StandardIdResponse>> call(
    String tableName,
    CreateLookupItemRequest req,
  ) async {
    final mutationId = _uuid.v4();
    final mutation = CreateLookupItemMutation(
      id: mutationId,
      aggregateId: mutationId,
      expectedVersion: 0,
      createdAt: _clock.now(),
      tableName: tableName,
      request: req,
    );
    final enqueue = await _outbox.enqueue(mutation);
    switch (enqueue) {
      case Failure(:final error, :final stackTrace):
        return Failure<StandardIdResponse>(error, stackTrace: stackTrace);
      case Success():
        unawaited(_engine.triggerDrain());
        return Success<StandardIdResponse>(
          StandardResponse<IdData>(
            data: IdData(id: mutationId),
            meta: ResponseMeta(timestamp: _clock.now().toIso8601String()),
          ),
        );
    }
  }
}
