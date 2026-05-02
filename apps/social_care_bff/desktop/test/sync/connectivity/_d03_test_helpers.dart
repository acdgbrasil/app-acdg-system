/// Shared scaffolding for D03 RED tests (`AutoDrainObserver` + friends).
///
/// `AutoDrainObserver` is the GoF Observer that subscribes to
/// `connectivity_plus` and fires-and-forgets `engine.triggerDrain()` on
/// every offline → online edge. Today this lives inline as the
/// `late SocialCareDesktop desktop` self-reference + closure inside
/// `social_care_desktop.dart::create()` (lines 333-343 of the post-D02
/// file). D03 extracts it to a standalone class with NO self-reference
/// — the closure now closes over the [SyncEngine] argument directly.
///
/// ── Reuse of existing fakes ─────────────────────────────────────────
/// We reuse:
///   * [FakeConnectivity] from `test/facade/_fakes/fake_connectivity.dart`
///     — already programmable (`emitOffline`, `emitOnline`, `emit(...)`,
///     `setCheckConnectivity(...)`, `streamSubscriptionCount`,
///     `hasListener`). NO need for a new fake.
///   * [FakeSyncEngine] from `test/use_cases/_fakes/fake_sync_engine.dart`
///     — already records `triggerDrainCount`. NO need for a new spy.
///
/// Both fakes are shipped as-is. This helper file just re-exports them
/// behind a cleaner local alias and provides one tiny ergonomic builder
/// (`buildEngineSpy`) that matches the D03 test cadence.
///
/// ── REGRA #2 — what the helpers DON'T do ────────────────────────────
/// They do NOT instantiate the real [SyncEngine.triggerDrain] dispatch
/// chain. The whole point of the Observer test is to verify the EDGE
/// detection — counting `triggerDrain` invocations on a spy is the
/// cleanest signal. Exercising the real drain would re-test
/// `pumping_sync_engine_test.dart`'s territory (D01 W0.5) and pull in
/// outbox + remote fakes for no test value.
///
/// IMPORTANT (RED phase): the import below resolves to a file W1 has
/// not created yet — `lib/src/sync/connectivity/auto_drain_observer.dart`.
/// Until then this helper file fails to analyze. That is the intended
/// RED signal.
library;

// ── Auto-drain observer under test (RED — file does not exist yet) ──
// ignore: uri_does_not_exist
export 'package:social_care_desktop/src/sync/connectivity/auto_drain_observer.dart';

// ── Reusable fakes ──────────────────────────────────────────────────
export '../../facade/_fakes/fake_connectivity.dart';
// ignore: implementation_imports
export '../../use_cases/_fakes/fake_sync_engine.dart';
