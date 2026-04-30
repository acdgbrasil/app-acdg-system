/// Recording stub for [SyncEngine] used by use case tests (A18b-v2).
///
/// Use cases depend on `SyncEngine` (concrete, not abstract). The real
/// engine drains the Outbox and dispatches via remotes — but A18b tests
/// only care that write use cases call `triggerDrain()` after a
/// successful enqueue. Exercising the real drain here would re-test
/// A18a's contract instead of A18b's pattern.
///
/// This fake `extends SyncEngine`, passing throw-away fakes for the
/// 5 sub-contract dependencies the parent constructor requires. The
/// parent's drain logic is bypassed by overriding `triggerDrain`,
/// `start`, `stop`, and `close`. The fake records:
///   * `triggerDrainCount` — how many times use cases asked for a drain.
///   * `started` / `closed` — lifecycle flags for tests that exercise
///     start/stop.
///
/// REGRA #2 — Why a fake instead of the real engine?
///   Use case tests assert: "after enqueue, was triggerDrain called?".
///   They MUST NOT exercise the dispatcher chain (which is A18a's
///   territory). A real engine would race the test (drain runs async,
///   would mark the row in_flight before the test reads it). The fake
///   freezes that race so axes stay deterministic.
library;

import 'package:core_contracts/core_contracts.dart';
// ignore_for_file: depend_on_referenced_packages
import 'package:shared/shared.dart';
import 'package:social_care_desktop/social_care_desktop.dart';

/// Recording stub for [SyncEngine].
///
/// Constructed without arguments — the parent's required dependencies
/// are filled with `_NoopX` fakes that throw if any contract method is
/// invoked (they shouldn't be — the fake's overrides bypass dispatch).
class FakeSyncEngine extends SyncEngine {
  FakeSyncEngine()
      : super(
          outbox: _ThrowingOutboxRepository(),
          registry: _ThrowingRegistryContract(),
          assessment: _ThrowingAssessmentContract(),
          care: _ThrowingCareContract(),
          protection: _ThrowingProtectionContract(),
          lookup: _ThrowingLookupContract(),
        );

  /// Counts every call to [triggerDrain]. Tests assert this is 1 after
  /// a single optimistic write, 2 after concurrent writes, etc.
  int triggerDrainCount = 0;

  /// True between [start] and [stop]/[close].
  bool started = false;

  /// True after [close]. Subsequent triggers stay no-op (no Failure here
  /// since A18b cares only that the count was bumped).
  bool closed = false;

  /// If non-null, [triggerDrain] returns this Result instead of the
  /// canned `Success(DrainSummary)`. Lets tests force engine failure if
  /// needed (none of the locked axes do, but the hook is here).
  Result<DrainSummary>? triggerDrainOverride;

  @override
  Future<void> start() async {
    started = true;
    closed = false;
  }

  @override
  Future<void> stop() async {
    started = false;
  }

  @override
  Future<void> close() async {
    closed = true;
    started = false;
  }

  @override
  Future<Result<DrainSummary>> triggerDrain() async {
    triggerDrainCount++;
    if (triggerDrainOverride != null) return triggerDrainOverride!;
    return const Success(
      DrainSummary(
        processed: 0,
        completed: 0,
        failedRetriable: 0,
        failedDead: 0,
      ),
    );
  }
}

// ── Throw-away dependencies ──────────────────────────────────────────────
// The use case is supposed to call `engine.triggerDrain()` only — never
// reach into the real dispatcher. These fakes throw if the override is
// bypassed, which would expose a use case bug.

class _ThrowingOutboxRepository implements OutboxRepository {
  @override
  Future<Result<void>> enqueue(SyncMutation mutation) async =>
      throw StateError('FakeSyncEngine should not call OutboxRepository');

  @override
  Future<Result<List<OutboxEntry>>> listByStatus(
    OutboxStatus status, {
    int? limit,
  }) async =>
      throw StateError('FakeSyncEngine should not call OutboxRepository');

  @override
  Future<Result<OutboxEntry?>> findById(String id) async =>
      throw StateError('FakeSyncEngine should not call OutboxRepository');

  @override
  Future<Result<void>> markInFlight(String id) async =>
      throw StateError('FakeSyncEngine should not call OutboxRepository');

  @override
  Future<Result<void>> markCompleted(String id) async =>
      throw StateError('FakeSyncEngine should not call OutboxRepository');

  @override
  Future<Result<void>> markFailedRetriable(String id, String error) async =>
      throw StateError('FakeSyncEngine should not call OutboxRepository');

  @override
  Future<Result<void>> markFailedDead(String id, String error) async =>
      throw StateError('FakeSyncEngine should not call OutboxRepository');

  @override
  Future<Result<void>> resetToPending(String id) async =>
      throw StateError('FakeSyncEngine should not call OutboxRepository');

  @override
  Future<Result<void>> clear() async =>
      throw StateError('FakeSyncEngine should not call OutboxRepository');
}

/// Helper that throws — every parent dispatch path is bypassed by the
/// `triggerDrain` override, so these methods never run.
Never _shouldNotBeCalled(String name) =>
    throw StateError('FakeSyncEngine should not call $name');

class _ThrowingRegistryContract implements RegistryContract {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _shouldNotBeCalled('RegistryContract.${invocation.memberName}');
}

class _ThrowingAssessmentContract implements AssessmentContract {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _shouldNotBeCalled('AssessmentContract.${invocation.memberName}');
}

class _ThrowingCareContract implements CareContract {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _shouldNotBeCalled('CareContract.${invocation.memberName}');
}

class _ThrowingProtectionContract implements ProtectionContract {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _shouldNotBeCalled('ProtectionContract.${invocation.memberName}');
}

class _ThrowingLookupContract implements LookupContract {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _shouldNotBeCalled('LookupContract.${invocation.memberName}');
}
