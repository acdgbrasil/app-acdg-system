/// Failure type returned by the sync layer (Outbox + SyncEngine) when
/// an underlying operation throws (DB closed, schema mismatch, post-close
/// drain, …). Mirrors `CacheFailure` — the impl boundary converts every
/// raw exception into a typed `Failure(SyncFailure(...))` so callers
/// never see raw Drift / SQLite errors leak across the layer.
class SyncFailure implements Exception {
  SyncFailure(this.cause);

  /// The original exception thrown by the underlying DAO / Drift call,
  /// or a sentinel String like "SyncEngine closed" for engine-state
  /// guards. Kept opaque so consumers don't pattern-match on driver
  /// internals.
  final Object cause;

  @override
  String toString() => 'SyncFailure: $cause';
}
