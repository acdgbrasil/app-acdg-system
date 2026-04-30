/// BFF implementation for Desktop (in-process).
///
/// A16-v2 (Onda 4) — exposes 7 thin remotes, one per sub-contract.
/// A17-v2 (Onda 4) — adds 5 cache contracts (Aggregate-Root aligned)
/// implemented over Drift in `_shared/cache_database.dart`. Impls and
/// the orchestrating facade are wired by A18-v2.
library;

export 'src/remote/assessment_remote.dart';
export 'src/remote/audit_remote.dart';
export 'src/remote/care_remote.dart';
export 'src/remote/health_remote.dart';
export 'src/remote/lookup_remote.dart';
export 'src/remote/protection_remote.dart';
export 'src/remote/registry_remote.dart';

// Cache contracts (A17-v2). Impls are wired by A18-v2's facade.
export 'src/cache/contracts/audit_cache.dart';
export 'src/cache/contracts/care_cache.dart';
export 'src/cache/contracts/lookup_cache.dart';
export 'src/cache/contracts/patients_cache.dart';
export 'src/cache/contracts/protection_cache.dart';

// Sync infra (A18a-v2). Public types for A18b/c to consume.
// `DriftOutboxRepository` and `SyncDatabase` stay library-private — the
// facade instantiates them internally.
export 'src/sync/_shared/failures.dart' show SyncFailure;
export 'src/sync/engine/conflict_resolver.dart'
    show
        CompletedDecision,
        ConflictResolver,
        DeadDecision,
        RetriableDecision,
        SyncDecision;
export 'src/sync/engine/retry_policy.dart' show RetryPolicy;
export 'src/sync/engine/sync_engine.dart' show DrainSummary, SyncEngine;
export 'src/sync/outbox/outbox_repository.dart'
    show OutboxEntry, OutboxRepository, OutboxStatus;
export 'src/sync/outbox/sync_mutation.dart';
