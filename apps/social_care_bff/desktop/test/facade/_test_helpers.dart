/// Shared scaffolding for A18c-v2 facade tests.
///
/// Builds a programmable test context for [SocialCareDesktop]:
///   * [FakeConnectivity] — controls the offline ↔ online edges that drive
///     the connectivity listener (D5 γ).
///   * `FakeXBff` instances from `bff/shared/lib/src/testing/` for the
///     7 sub-contracts. The facade wires these into the use cases so we
///     can drive end-to-end scenarios without touching real HTTP.
///   * `FakeClock` — deterministic clock so factory-time `meta.timestamp`
///     values are stable.
///   * `Dio` — a real Dio instance is unused in these tests (the fakes
///     replace remotes), but the facade's factory takes a `Dio?` for
///     override; we pass a `Dio()` so the factory doesn't reach into
///     `getApplicationDocumentsDirectory()` on its own.
///
/// IMPORTANT (RED phase): the facade module
/// `lib/src/facade/social_care_desktop.dart` does NOT exist yet. The
/// `import` line below fails — that is the intended RED signal. W1
/// implements the facade + 7 sub-facades.
///
/// Boundary callout: `_test_helpers.dart` does NOT touch `packages/*`.
/// W1 must mirror that boundary: the facade is built entirely from
/// types in `bff/shared/`, `core_contracts/`, and `social_care_desktop/`
/// itself.
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:social_care_desktop/social_care_desktop.dart' show Clock;

// ── Facade (RED — does not exist yet) ────────────────────────────────────
// ignore: uri_does_not_exist, unused_import
import 'package:social_care_desktop/src/facade/social_care_desktop.dart';
// ignore: uri_does_not_exist, unused_import
import 'package:social_care_desktop/src/facade/sub_facades/registry_facade.dart';
// ignore: uri_does_not_exist, unused_import
import 'package:social_care_desktop/src/facade/sub_facades/assessment_facade.dart';
// ignore: uri_does_not_exist, unused_import
import 'package:social_care_desktop/src/facade/sub_facades/care_facade.dart';
// ignore: uri_does_not_exist, unused_import
import 'package:social_care_desktop/src/facade/sub_facades/protection_facade.dart';
// ignore: uri_does_not_exist, unused_import
import 'package:social_care_desktop/src/facade/sub_facades/audit_facade.dart';
// ignore: uri_does_not_exist, unused_import
import 'package:social_care_desktop/src/facade/sub_facades/lookup_facade.dart';
// ignore: uri_does_not_exist, unused_import
import 'package:social_care_desktop/src/facade/sub_facades/health_facade.dart';

import '_fakes/fake_connectivity.dart';

export 'package:social_care_desktop/social_care_desktop.dart';
// ignore: uri_does_not_exist
export 'package:social_care_desktop/src/facade/social_care_desktop.dart';
// ignore: uri_does_not_exist
export 'package:social_care_desktop/src/facade/sub_facades/registry_facade.dart';
// ignore: uri_does_not_exist
export 'package:social_care_desktop/src/facade/sub_facades/assessment_facade.dart';
// ignore: uri_does_not_exist
export 'package:social_care_desktop/src/facade/sub_facades/care_facade.dart';
// ignore: uri_does_not_exist
export 'package:social_care_desktop/src/facade/sub_facades/protection_facade.dart';
// ignore: uri_does_not_exist
export 'package:social_care_desktop/src/facade/sub_facades/audit_facade.dart';
// ignore: uri_does_not_exist
export 'package:social_care_desktop/src/facade/sub_facades/lookup_facade.dart';
// ignore: uri_does_not_exist
export 'package:social_care_desktop/src/facade/sub_facades/health_facade.dart';

export '_fakes/fake_connectivity.dart';

/// Test context bundling fakes + factory params for [SocialCareDesktop].
///
/// `cacheFilePath` and `syncQueueFilePath` are set to `':memory:'`
/// so Drift uses in-memory databases — `path_provider` is not exercised.
/// One test verifies the default-paths behavior separately.
class FacadeTestContext {
  FacadeTestContext._({
    required this.fakeConnectivity,
    required this.fakeClock,
    required this.dio,
  });

  /// Spins up a fresh, isolated context with all defaults.
  ///
  /// The default `cacheFilePath` / `syncQueueFilePath` is `':memory:'`
  /// (Drift's in-memory marker). Tests that want disk persistence pass
  /// explicit paths to `SocialCareDesktop.create()` themselves.
  static FacadeTestContext fresh({
    DateTime? now,
    List<ConnectivityResult>? bootConnectivity,
  }) {
    final connectivity = FakeConnectivity(
      defaultResults: bootConnectivity ?? const [ConnectivityResult.wifi],
    );
    return FacadeTestContext._(
      fakeConnectivity: connectivity,
      fakeClock: FakeClock(now ?? DateTime.utc(2026, 5, 1, 12)),
      dio: Dio(),
    );
  }

  final FakeConnectivity fakeConnectivity;
  final FakeClock fakeClock;
  final Dio dio;

  /// Tears down the connectivity stream controller. Tests should chain
  /// this AFTER `desktop.close()` so the facade's subscription is
  /// cancelled first (the fake's close becomes a no-op then).
  Future<void> close() async {
    try {
      await fakeConnectivity.close();
    } catch (_) {}
  }
}

/// Programmable clock — same shape as A18b's `FakeClock`. Local copy
/// keeps the facade test suite self-contained (no cross-suite import).
class FakeClock implements Clock {
  FakeClock(this._now);
  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration delta) {
    _now = _now.add(delta);
  }

  void setTo(DateTime t) {
    _now = t;
  }
}

/// Token provider that always returns the same string. Tests don't
/// exercise auth refresh paths — that's the upstream Dio interceptor's
/// concern (A11/A12). The facade just needs SOMETHING to inject.
String? Function() kStaticToken(String? value) =>
    () => value;
