/// Immutable bundle of every dependency `SocialCareDesktop._()` needs.
///
/// Pre-D03 the facade's private constructor took 14 individual named
/// parameters. D03 collapses those into a single [DesktopRuntime] data
/// class that [DesktopAssembler.build] populates and the facade
/// delegates to via getters.
///
/// The class has no behaviour — every test exercises structural
/// guarantees (12 fields, 12 expected static types, instance
/// independence). Behaviour lives in the assembler that builds it and
/// the facade that consumes it.
library;

import 'dart:async';

import '../../cache/_shared/cache_database.dart';
import '../../sync/_shared/sync_database.dart';
import '../../sync/connectivity/auto_drain_observer.dart';
import '../../sync/engine/sync_engine.dart';
import '../sub_facades/assessment_facade.dart';
import '../sub_facades/audit_facade.dart';
import '../sub_facades/care_facade.dart';
import '../sub_facades/health_facade.dart';
import '../sub_facades/lookup_facade.dart';
import '../sub_facades/protection_facade.dart';
import '../sub_facades/registry_facade.dart';

/// Bundles the 12 fields produced by [DesktopAssembler.build] — the
/// 5 infrastructure pieces (databases + engine + observer + drain
/// controller) and the 7 sub-facades. Consumed by `SocialCareDesktop`
/// via getters that delegate to these fields.
class DesktopRuntime {
  const DesktopRuntime({
    required this.cacheDb,
    required this.syncDb,
    required this.engine,
    required this.connectivityObserver,
    required this.drainController,
    required this.registry,
    required this.assessment,
    required this.care,
    required this.protection,
    required this.audit,
    required this.lookup,
    required this.health,
  });

  // ── Infrastructure (5) ─────────────────────────────────────────────

  final CacheDatabase cacheDb;
  final SyncDatabase syncDb;
  final SyncEngine engine;
  final AutoDrainObserver connectivityObserver;
  final StreamController<DrainSummary> drainController;

  // ── Sub-facades (7) ────────────────────────────────────────────────

  final RegistryFacade registry;
  final AssessmentFacade assessment;
  final CareFacade care;
  final ProtectionFacade protection;
  final AuditFacade audit;
  final LookupFacade lookup;
  final HealthFacade health;
}
