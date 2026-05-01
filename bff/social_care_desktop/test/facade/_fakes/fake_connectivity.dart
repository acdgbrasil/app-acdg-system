/// Programmable [Connectivity] fake for A18c-v2 facade tests.
///
/// `connectivity_plus`'s [Connectivity] is a singleton with a private
/// constructor (`Connectivity._()` + `factory Connectivity()`), so a
/// real instance cannot be created in tests without touching the
/// platform plugin. The class itself is NOT `final`/`sealed`, so we can
/// `implements` it and inject our fake via
/// `SocialCareDesktop.create(connectivity: ...)`.
///
/// The fake exposes:
///   * [emitOffline] / [emitOnline] / [emitOnlineMobile] — push controlled
///     events into [onConnectivityChanged] so tests can simulate
///     transitions (offline → online triggers a drain per D5 γ).
///   * `defaultResults` — what [checkConnectivity] returns. Default
///     `[ConnectivityResult.wifi]` (online) so factory-time probes don't
///     surface as offline by accident.
///
/// REGRA #2 — Why a fake instead of mocktail:
///   The contract for the facade is "subscribe to onConnectivityChanged
///   on `create()`, cancel the subscription on `close()`". A
///   programmable fake makes the offline→online edge explicit and lets
///   the `closed.assertion` test verify `_controller.hasListener` after
///   close. Mocktail would obscure that contract.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class FakeConnectivity implements Connectivity {
  FakeConnectivity({
    List<ConnectivityResult> defaultResults = const [ConnectivityResult.wifi],
  }) : _defaultResults = defaultResults;

  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  /// What [checkConnectivity] returns (e.g. for factory-time probes).
  /// Tests that need an "offline at boot" scenario can pass
  /// `[ConnectivityResult.none]` here.
  List<ConnectivityResult> _defaultResults;

  /// Replaces the canned [checkConnectivity] result. Useful for tests
  /// that want subsequent probes to differ from the boot-time one.
  void setCheckConnectivity(List<ConnectivityResult> results) {
    _defaultResults = results;
  }

  /// True until [close] is called. The facade's `close()` must cancel
  /// its subscription, which is observable via [hasListener].
  bool get hasListener => _controller.hasListener;

  /// Tracks how many times [onConnectivityChanged] was accessed. Useful
  /// for confirming the facade subscribes once.
  int get streamSubscriptionCount => _streamSubscriptions;
  int _streamSubscriptions = 0;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    _streamSubscriptions++;
    return _controller.stream;
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _defaultResults;

  /// Pushes a `[ConnectivityResult.none]` event — simulates network loss.
  void emitOffline() {
    _controller.add(const [ConnectivityResult.none]);
  }

  /// Pushes a `[ConnectivityResult.wifi]` event — simulates LAN restore.
  void emitOnline() {
    _controller.add(const [ConnectivityResult.wifi]);
  }

  /// Pushes a `[ConnectivityResult.mobile]` event — simulates 4G/5G
  /// restore. Same `online` semantics as wifi for the trigger; tests
  /// use this to ensure ANY non-`none` result counts as online.
  void emitOnlineMobile() {
    _controller.add(const [ConnectivityResult.mobile]);
  }

  /// Pushes a custom event — tests for exotic combinations
  /// (`[wifi, mobile]`, `[bluetooth, none]`, etc).
  void emit(List<ConnectivityResult> results) {
    _controller.add(results);
  }

  /// Releases the underlying StreamController. The facade's `close()`
  /// should cancel its subscription BEFORE this is called; tests that
  /// run `addTearDown(fake.close)` rely on that ordering.
  Future<void> close() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
