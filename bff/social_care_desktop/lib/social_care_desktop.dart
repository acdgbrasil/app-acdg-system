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

// Cache shared types (A18b-v2 surface — Cached<T> envelope).
export 'src/cache/_shared/cached.dart';

// Use case shared infra (A18b-v2). The 42 use cases below consume these.
export 'src/use_cases/_shared/clock.dart';
export 'src/use_cases/_shared/stale_policy.dart';
export 'src/use_cases/_shared/use_case_failures.dart';
export 'src/use_cases/_shared/version_extractor.dart';

// Use cases — Registry (13).
export 'src/use_cases/registry/admit_patient_use_case.dart';
export 'src/use_cases/registry/add_family_member_use_case.dart';
export 'src/use_cases/registry/assign_primary_caregiver_use_case.dart';
export 'src/use_cases/registry/discharge_patient_use_case.dart';
export 'src/use_cases/registry/fetch_patient_by_person_id_use_case.dart';
export 'src/use_cases/registry/fetch_patient_use_case.dart';
export 'src/use_cases/registry/list_patients_use_case.dart';
export 'src/use_cases/registry/readmit_patient_use_case.dart';
export 'src/use_cases/registry/register_patient_use_case.dart';
export 'src/use_cases/registry/remove_family_member_use_case.dart';
export 'src/use_cases/registry/search_patients_use_case.dart';
export 'src/use_cases/registry/update_social_identity_use_case.dart';
export 'src/use_cases/registry/withdraw_patient_use_case.dart';

// Use cases — Assessment (7).
export 'src/use_cases/assessment/update_community_support_network_use_case.dart';
export 'src/use_cases/assessment/update_educational_status_use_case.dart';
export 'src/use_cases/assessment/update_health_status_use_case.dart';
export 'src/use_cases/assessment/update_housing_condition_use_case.dart';
export 'src/use_cases/assessment/update_social_health_summary_use_case.dart';
export 'src/use_cases/assessment/update_socio_economic_situation_use_case.dart';
export 'src/use_cases/assessment/update_work_and_income_use_case.dart';

// Use cases — Care (3).
export 'src/use_cases/care/list_appointments_use_case.dart';
export 'src/use_cases/care/register_appointment_use_case.dart';
export 'src/use_cases/care/update_intake_info_use_case.dart';

// Use cases — Protection (6).
export 'src/use_cases/protection/create_referral_use_case.dart';
export 'src/use_cases/protection/fetch_placement_history_use_case.dart';
export 'src/use_cases/protection/list_referrals_use_case.dart';
export 'src/use_cases/protection/list_violation_reports_use_case.dart';
export 'src/use_cases/protection/report_violation_use_case.dart';
export 'src/use_cases/protection/update_placement_history_use_case.dart';

// Use cases — Audit (1).
export 'src/use_cases/audit/fetch_audit_trail_use_case.dart';

// Use cases — Lookup (10).
export 'src/use_cases/lookup/approve_lookup_request_use_case.dart';
export 'src/use_cases/lookup/create_lookup_item_use_case.dart';
export 'src/use_cases/lookup/create_lookup_request_use_case.dart';
export 'src/use_cases/lookup/find_lookup_request_by_id_use_case.dart';
export 'src/use_cases/lookup/get_lookup_table_use_case.dart';
export 'src/use_cases/lookup/get_lookups_batch_use_case.dart';
export 'src/use_cases/lookup/list_lookup_requests_use_case.dart';
export 'src/use_cases/lookup/reject_lookup_request_use_case.dart';
export 'src/use_cases/lookup/toggle_lookup_item_use_case.dart';
export 'src/use_cases/lookup/update_lookup_item_use_case.dart';

// Use cases — Health (2).
export 'src/use_cases/health/check_health_use_case.dart';
export 'src/use_cases/health/check_ready_use_case.dart';
