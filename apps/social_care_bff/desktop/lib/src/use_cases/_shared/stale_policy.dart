/// Encapsulates the stale-data threshold check used by Pattern-1 read
/// use cases.
///
/// Default `staleAfter` is 5 minutes (REGRA #2 #1, locked in master
/// A18 STATE). Each read use case accepts an override `Duration`
/// constructor parameter, so per-use-case latitude (e.g. 24h for
/// rarely-changing lookup tables, 30s for hot data) stays open.
library;

class StalePolicy {
  const StalePolicy({this.staleAfter = const Duration(minutes: 5)});

  final Duration staleAfter;

  /// Returns `true` if `cachedAt` is older than `now - staleAfter`.
  ///
  /// `now` is injected so tests can drive a `FakeClock` deterministically;
  /// production callers pass the wall clock. The contract is that
  /// callers populate `cachedAt` from the same clock — i.e. cache impls
  /// stamp rows via the injected `Clock` rather than the unmanaged
  /// `DateTime.now()`. With that invariant, future-relative `cachedAt`
  /// is impossible.
  bool isStale(DateTime cachedAt, {required DateTime now}) =>
      now.difference(cachedAt) > staleAfter;
}
