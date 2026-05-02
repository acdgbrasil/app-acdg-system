/// Failure type returned by Drift-backed cache impls when an underlying
/// database operation throws (DB closed, schema mismatch, disk error,
/// …). Mirrors the `BackendErrorResponse` pattern used by the remotes:
/// the impl boundary converts every raw exception into a typed
/// `Failure<CacheFailure>` so callers never see raw Drift / SQLite
/// errors leak across the layer.
class CacheFailure implements Exception {
  CacheFailure(this.cause);

  /// The original exception thrown by the underlying DAO / Drift call.
  /// Kept opaque so consumers don't pattern-match on driver internals.
  final Object cause;

  @override
  String toString() => 'CacheFailure: $cause';
}
