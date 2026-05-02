import 'dart:async';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../cache/contracts/patients_cache.dart';
import '../../sync/engine/sync_engine.dart';
import '../../sync/outbox/outbox_repository.dart';
import '../../sync/outbox/sync_mutation.dart';
import '../_shared/clock.dart';
import '../_shared/use_case_failures.dart';

/// Pattern 2 — patient-aggregate write (intake info hangs off the
/// patient aggregate, so version comes from `PatientsCache`).
class UpdateIntakeInfoUseCase {
  UpdateIntakeInfoUseCase({
    required PatientsCache patientsCache,
    required OutboxRepository outbox,
    required SyncEngine engine,
    required Clock clock,
    Uuid? uuid,
  }) : _patientsCache = patientsCache,
       _outbox = outbox,
       _engine = engine,
       _clock = clock,
       _uuid = uuid ?? const Uuid();

  final PatientsCache _patientsCache;
  final OutboxRepository _outbox;
  final SyncEngine _engine;
  final Clock _clock;
  final Uuid _uuid;

  Future<Result<void>> call(
    String patientId,
    RegisterIntakeInfoRequest req,
  ) async {
    final cachedResult = await _patientsCache.findById(patientId);
    switch (cachedResult) {
      case Failure(:final error, :final stackTrace):
        return Failure<void>(error, stackTrace: stackTrace);
      case Success(:final value):
        if (value == null) {
          return Failure<void>(
            NotFoundFailure('Patient $patientId not in cache'),
          );
        }
        final mutation = UpdateIntakeInfoMutation(
          id: _uuid.v4(),
          aggregateId: patientId,
          expectedVersion: value.version,
          createdAt: _clock.now(),
          request: req,
        );
        final enqueue = await _outbox.enqueue(mutation);
        switch (enqueue) {
          case Failure(:final error, :final stackTrace):
            return Failure<void>(error, stackTrace: stackTrace);
          case Success():
            await _patientsCache.upsertPatient(
              value.dto,
              version: value.version + 1,
            );
            unawaited(_engine.triggerDrain());
            return const Success<void>(null);
        }
    }
  }
}
