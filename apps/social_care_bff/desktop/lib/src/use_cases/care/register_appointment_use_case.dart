import 'dart:async';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../cache/contracts/care_cache.dart';
import '../../sync/engine/sync_engine.dart';
import '../../sync/outbox/outbox_repository.dart';
import '../../sync/outbox/sync_mutation.dart';
import '../_shared/clock.dart';

/// Pattern 2 — register-style write. Aggregate is `appointment`
/// (server-side generates the id); cache is unused at enqueue time.
class RegisterAppointmentUseCase {
  RegisterAppointmentUseCase({
    required CareCache careCache,
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
    String patientId,
    RegisterAppointmentRequest req,
  ) async {
    final mutationId = _uuid.v4();
    final mutation = RegisterAppointmentMutation(
      id: mutationId,
      aggregateId: mutationId,
      expectedVersion: 0,
      createdAt: _clock.now(),
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
