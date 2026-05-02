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

/// Pattern 2 — patient-aggregate write.
///
/// Order of operations (locked, REGRA #2 #2 — no rollback on failed_dead):
///   1. Read cached patient version (NotFoundFailure if missing).
///   2. Build mutation with `expectedVersion = cached.version`.
///   3. Enqueue (durable record before optimistic update).
///   4. Optimistic cache upsert at `cached.version + 1`.
///   5. Trigger engine drain (fire-and-forget).
///
/// If step 3 fails, cache is untouched and engine is NOT triggered.
class DischargePatientUseCase {
  DischargePatientUseCase({
    required PatientsCache cache,
    required OutboxRepository outbox,
    required SyncEngine engine,
    required Clock clock,
    Uuid? uuid,
  }) : _cache = cache,
       _outbox = outbox,
       _engine = engine,
       _clock = clock,
       _uuid = uuid ?? const Uuid();

  final PatientsCache _cache;
  final OutboxRepository _outbox;
  final SyncEngine _engine;
  final Clock _clock;
  final Uuid _uuid;

  Future<Result<void>> call(
    String patientId,
    DischargePatientRequest req,
  ) async {
    final cachedResult = await _cache.findById(patientId);
    switch (cachedResult) {
      case Failure(:final error, :final stackTrace):
        return Failure<void>(error, stackTrace: stackTrace);
      case Success(:final value):
        if (value == null) {
          return Failure<void>(
            NotFoundFailure('Patient $patientId not in cache'),
          );
        }
        final mutation = DischargePatientMutation(
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
            await _cache.upsertPatient(value.dto, version: value.version + 1);
            unawaited(_engine.triggerDrain());
            return const Success<void>(null);
        }
    }
  }
}
