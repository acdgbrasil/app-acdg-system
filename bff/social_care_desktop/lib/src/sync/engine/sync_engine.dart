import 'dart:isolate';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../_shared/failures.dart';
import '../outbox/outbox_repository.dart';
import '../outbox/sync_mutation.dart';
import 'conflict_resolver.dart';
import 'retry_policy.dart';

/// Threshold above which the drain pre-deserializes the entire pending
/// batch in a background isolate (per Concurrency Policy §C1).
///
/// Per-entry isolate would defeat the purpose (spawn cost ~0.5–2ms vs.
/// deserialization ~0.1–1ms each). One isolate hop for the whole batch
/// amortizes spawn across N mutations — true win for offline → online
/// recovery scenarios where N can reach 50–500.
const int _drainBatchIsolateThreshold = 50;

/// Outcome counters for one drain pass. Returned by
/// [SyncEngine.triggerDrain] so callers can surface progress in the UI
/// (`processed = completed + failedRetriable + failedDead`).
class DrainSummary {
  const DrainSummary({
    required this.processed,
    required this.completed,
    required this.failedRetriable,
    required this.failedDead,
  });

  final int processed;
  final int completed;
  final int failedRetriable;
  final int failedDead;
}

/// Orchestrator that drains the Outbox and dispatches each
/// [SyncMutation] to the right sub-contract write method. Owns the
/// state machine for an Outbox row across its lifecycle:
///
/// ```
/// pending ─pickup─→ in_flight ─success─→ completed
///                          ├─409──────→ failed_dead
///                          ├─5xx/net──→ failed_retriable ─reset─→ pending
///                          └─4xx other→ failed_dead
/// ```
///
/// Single-flight: concurrent calls to [triggerDrain] share the same
/// in-flight Future. Lifecycle is app-controlled (D4 α): [start]
/// enables drain, [stop] suspends it (rows stay pending), [close]
/// makes subsequent triggers fail loudly.
class SyncEngine {
  SyncEngine({
    required OutboxRepository outbox,
    required RegistryContract registry,
    required AssessmentContract assessment,
    required CareContract care,
    required ProtectionContract protection,
    required LookupContract lookup,
    RetryPolicy retryPolicy = const RetryPolicy(),
    ConflictResolver conflictResolver = const ConflictResolver(),
  }) : _outbox = outbox,
       _registry = registry,
       _assessment = assessment,
       _care = care,
       _protection = protection,
       _lookup = lookup,
       _retryPolicy = retryPolicy,
       _conflictResolver = conflictResolver;

  final OutboxRepository _outbox;
  final RegistryContract _registry;
  final AssessmentContract _assessment;
  final CareContract _care;
  final ProtectionContract _protection;
  final LookupContract _lookup;
  final RetryPolicy _retryPolicy;
  final ConflictResolver _conflictResolver;

  bool _started = false;
  bool _closed = false;
  Future<Result<DrainSummary>>? _inFlight;

  /// Enables drain. After [start], [triggerDrain] processes pending
  /// rows. Idempotent — calling twice has no effect.
  Future<void> start() async {
    if (_closed) return;
    _started = true;
  }

  /// Suspends drain. Pending rows remain in the queue; subsequent
  /// [triggerDrain] calls return `Success(processed: 0)` until [start]
  /// is called again.
  Future<void> stop() async {
    _started = false;
  }

  /// Releases resources. Subsequent [triggerDrain] calls return
  /// `Failure(SyncFailure)` — the engine cannot dispatch after close.
  Future<void> close() async {
    _closed = true;
    _started = false;
  }

  /// Drains the Outbox.
  ///
  /// Returns `Success(DrainSummary(processed: 0, ...))` if the engine
  /// is not started (no-op pre-start) or `Failure(SyncFailure)` if it
  /// has been closed. Concurrent calls share the same in-flight Future
  /// (single-flight).
  Future<Result<DrainSummary>> triggerDrain() {
    if (_closed) {
      return Future.value(
        Failure<DrainSummary>(SyncFailure('SyncEngine closed')),
      );
    }
    if (!_started) {
      return Future.value(
        const Success(
          DrainSummary(
            processed: 0,
            completed: 0,
            failedRetriable: 0,
            failedDead: 0,
          ),
        ),
      );
    }
    final existing = _inFlight;
    if (existing != null) return existing;
    final fut = _drainImpl();
    _inFlight = fut;
    return fut.whenComplete(() => _inFlight = null);
  }

  Future<Result<DrainSummary>> _drainImpl() async {
    try {
      final pendingRes = await _outbox.listByStatus(OutboxStatus.pending);
      switch (pendingRes) {
        case Failure<List<OutboxEntry>>(:final error, :final stackTrace):
          return Failure<DrainSummary>(error, stackTrace: stackTrace);
        case Success<List<OutboxEntry>>(:final value):
          // T2.3: pre-deserialize the entire pending batch in one
          // isolate hop when above threshold. The dispatch loop then
          // reads pre-typed mutations — zero per-entry main-thread
          // deserialization cost. Behavior preserved: same indexing,
          // same per-entry dispatch semantics, same outbox marks.
          final mutations = await _deserializeBatch(value);

          var processed = 0;
          var completed = 0;
          var failedRetriable = 0;
          var failedDead = 0;
          for (var i = 0; i < value.length; i++) {
            final entry = value[i];
            final mutation = mutations[i];
            processed++;
            await _outbox.markInFlight(entry.id);

            final result = await _dispatch(mutation);

            switch (result) {
              case Success<void>():
                await _outbox.markCompleted(entry.id);
                completed++;
              case Failure<void>(:final error):
                final decision = _conflictResolver.decide(error);
                switch (decision) {
                  case CompletedDecision():
                    await _outbox.markCompleted(entry.id);
                    completed++;
                  case RetriableDecision(:final reason):
                    final nextAttempt = entry.attemptCount + 1;
                    if (_retryPolicy.shouldRetry(nextAttempt)) {
                      await _outbox.markFailedRetriable(entry.id, reason);
                      failedRetriable++;
                    } else {
                      await _outbox.markFailedDead(
                        entry.id,
                        'Max attempts reached: $reason',
                      );
                      failedDead++;
                    }
                  case DeadDecision(:final reason):
                    await _outbox.markFailedDead(entry.id, reason);
                    failedDead++;
                }
            }
          }
          return Success(
            DrainSummary(
              processed: processed,
              completed: completed,
              failedRetriable: failedRetriable,
              failedDead: failedDead,
            ),
          );
      }
    } catch (e, st) {
      return Failure<DrainSummary>(SyncFailure(e), stackTrace: st);
    }
  }

  /// Pre-deserializes the entire pending batch into typed mutations,
  /// optionally off the main isolate.
  ///
  /// Per T2.3 (2026-05-01) + Concurrency Policy §C1: when [entries]
  /// has more than [_drainBatchIsolateThreshold] members, we pay one
  /// isolate spawn cost and deserialize all in a single hop. Below the
  /// threshold, deserialization stays inline (spawn cost would be
  /// strictly net-negative).
  ///
  /// **Sendable contract:** [SyncMutation.fromOutboxEntry] is a static
  /// factory + sealed-class switch over [OutboxEntry]; both
  /// `OutboxEntry` (record-like data class with primitive fields +
  /// `Map<String, dynamic> payload`) and the resulting `SyncMutation`
  /// final classes are sendable across isolate boundaries.
  ///
  /// **Order contract:** the returned list mirrors [entries] index-by-
  /// index. The dispatch loop relies on this for FIFO ordering and
  /// per-entry outbox marking.
  Future<List<SyncMutation>> _deserializeBatch(
    List<OutboxEntry> entries,
  ) async {
    if (entries.length <= _drainBatchIsolateThreshold) {
      return entries.map(SyncMutation.fromOutboxEntry).toList();
    }
    return Isolate.run<List<SyncMutation>>(
      () => entries.map(SyncMutation.fromOutboxEntry).toList(),
    );
  }

  /// Dispatches a typed [SyncMutation] to the corresponding sub-contract
  /// write method. The sealed-class switch is compiler-enforced
  /// exhaustive — adding a 28th mutation requires a new arm here.
  Future<Result<void>> _dispatch(SyncMutation m) async {
    switch (m) {
      case RegisterPatientMutation():
        return _voidOnId(await _registry.registerPatient(m.request));
      case AddFamilyMemberMutation():
        return _registry.addFamilyMember(m.aggregateId, m.request);
      case RemoveFamilyMemberMutation():
        return _registry.removeFamilyMember(m.aggregateId, m.memberId);
      case AssignPrimaryCaregiverMutation():
        return _registry.assignPrimaryCaregiver(m.aggregateId, m.request);
      case UpdateSocialIdentityMutation():
        return _registry.updateSocialIdentity(m.aggregateId, m.request);
      case DischargePatientMutation():
        return _registry.dischargePatient(m.aggregateId, m.request);
      case ReadmitPatientMutation():
        return _registry.readmitPatient(m.aggregateId, m.request);
      case AdmitPatientMutation():
        return _registry.admitPatient(m.aggregateId);
      case WithdrawPatientMutation():
        return _registry.withdrawPatient(m.aggregateId, m.request);
      case UpdateHealthStatusMutation():
        return _assessment.updateHealthStatus(m.aggregateId, m.request);
      case UpdateHousingConditionMutation():
        return _assessment.updateHousingCondition(m.aggregateId, m.request);
      case UpdateEducationalStatusMutation():
        return _assessment.updateEducationalStatus(m.aggregateId, m.request);
      case UpdateSocioEconomicSituationMutation():
        return _assessment.updateSocioEconomicSituation(
          m.aggregateId,
          m.request,
        );
      case UpdateWorkAndIncomeMutation():
        return _assessment.updateWorkAndIncome(m.aggregateId, m.request);
      case UpdateCommunitySupportNetworkMutation():
        return _assessment.updateCommunitySupportNetwork(
          m.aggregateId,
          m.request,
        );
      case UpdateSocialHealthSummaryMutation():
        return _assessment.updateSocialHealthSummary(m.aggregateId, m.request);
      case RegisterAppointmentMutation():
        return _voidOnId(
          await _care.registerAppointment(m.aggregateId, m.request),
        );
      case UpdateIntakeInfoMutation():
        return _care.updateIntakeInfo(m.aggregateId, m.request);
      case UpdatePlacementHistoryMutation():
        return _protection.updatePlacementHistory(m.aggregateId, m.request);
      case ReportViolationMutation():
        return _voidOnId(
          await _protection.reportViolation(m.aggregateId, m.request),
        );
      case CreateReferralMutation():
        return _voidOnId(
          await _protection.createReferral(m.aggregateId, m.request),
        );
      case CreateLookupItemMutation():
        return _voidOnId(
          await _lookup.createLookupItem(m.tableName, m.request),
        );
      case UpdateLookupItemMutation():
        return _voidOnStandard(
          await _lookup.updateLookupItem(m.tableName, m.aggregateId, m.request),
        );
      case ToggleLookupItemMutation():
        return _voidOnStandard(
          await _lookup.toggleLookupItem(m.tableName, m.aggregateId, m.request),
        );
      case CreateLookupRequestMutation():
        return _voidOnId(await _lookup.createLookupRequest(m.request));
      case ApproveLookupRequestMutation():
        return _voidOnStandard(
          await _lookup.approveLookupRequest(m.aggregateId),
        );
      case RejectLookupRequestMutation():
        return _voidOnStandard(
          await _lookup.rejectLookupRequest(m.aggregateId),
        );
    }
  }

  /// Discards the generated id from a `StandardIdResponse` — the engine
  /// only needs success/failure for state-transition purposes. The id
  /// is observable to use cases via the cache (write use cases store
  /// the optimistic local id and reconcile post-drain).
  Result<void> _voidOnId(Result<StandardIdResponse> r) {
    switch (r) {
      case Success<StandardIdResponse>():
        return const Success(null);
      case Failure<StandardIdResponse>(:final error, :final stackTrace):
        return Failure<void>(error, stackTrace: stackTrace);
    }
  }

  /// Discards the wrapped value from a `StandardResponse<void>` — same
  /// rationale as [_voidOnId].
  Result<void> _voidOnStandard(Result<StandardResponse<void>> r) {
    switch (r) {
      case Success<StandardResponse<void>>():
        return const Success(null);
      case Failure<StandardResponse<void>>(:final error, :final stackTrace):
        return Failure<void>(error, stackTrace: stackTrace);
    }
  }
}
