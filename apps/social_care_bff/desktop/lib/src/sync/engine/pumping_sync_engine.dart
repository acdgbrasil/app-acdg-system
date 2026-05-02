import 'dart:async';

import 'package:core_contracts/core_contracts.dart';

import 'sync_engine.dart';

/// [SyncEngine] subclass that pumps every successful drain summary onto
/// a broadcast controller. The facade exposes that controller as
/// `SocialCareDesktop.drainStream`, so UI panels see EVERY drain
/// completion — including the ones triggered fire-and-forget by write
/// use cases (which call `engine.triggerDrain()` directly).
///
/// Failures are NOT pumped — the panel UI surfaces them via the Result
/// returned from `triggerDrain` (or the engine's internal state). The
/// stream is intentionally success-only so a flapping connection
/// doesn't spam the UI with `Failure` events.
///
/// Closed-controller branch: when the broadcast controller has already
/// been closed (e.g. during shutdown sequences), the pump silently
/// short-circuits via the `isClosed` guard. The underlying `Result`
/// still propagates to the caller — pumping is observation, not gating.
class PumpingSyncEngine extends SyncEngine {
  PumpingSyncEngine({
    required super.outbox,
    required super.registry,
    required super.assessment,
    required super.care,
    required super.protection,
    required super.lookup,
    required StreamController<DrainSummary> drainController,
  }) : _drainController = drainController;

  final StreamController<DrainSummary> _drainController;

  @override
  Future<Result<DrainSummary>> triggerDrain() async {
    final result = await super.triggerDrain();
    switch (result) {
      case Success<DrainSummary>(:final value):
        if (!_drainController.isClosed) {
          _drainController.add(value);
        }
      case Failure<DrainSummary>():
        break;
    }
    return result;
  }
}
