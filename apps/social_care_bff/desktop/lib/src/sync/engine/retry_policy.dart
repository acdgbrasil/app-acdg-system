import 'dart:math' as math;

/// Pure value type encapsulating exponential-backoff math used by the
/// `SyncEngine` when scheduling retries of `failed_retriable` mutations.
///
/// No I/O, no time injection — every method is a pure function of the
/// `attemptCount` argument and the policy fields. Tests cover the math
/// in isolation.
///
/// Defaults (`maxAttempts = 10`, `maxDelay = 30 minutes`) match
/// STATE.md (D2 / RetryPolicy spec). Custom configs are accepted for
/// tighter retry envelopes (e.g. critical writes that should give up
/// after 3 attempts).
class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 10,
    this.maxDelay = const Duration(minutes: 30),
  });

  final int maxAttempts;
  final Duration maxDelay;

  /// Returns true while the row is still eligible for another retry
  /// (i.e. `attemptCount < maxAttempts`). The drain loop reads this
  /// after marking a mutation `failed_retriable` and demotes it to
  /// `failed_dead` when it returns false.
  bool shouldRetry(int attemptCount) => attemptCount < maxAttempts;

  /// Returns the delay before the next retry attempt:
  /// `2^attemptCount` seconds, capped at [maxDelay].
  ///
  /// For [attemptCount] = 0 we return 1 second (`2^0 = 1`).
  /// We clamp the exponent before raising so very large counts don't
  /// overflow `int` on 32-bit hosts.
  Duration nextDelay(int attemptCount) {
    final maxMs = maxDelay.inMilliseconds;
    // Beyond ~2^30 we are well past the cap; clamp early to avoid pow
    // overflow on 32-bit Web. 30 is also large enough that attemptCount
    // 11 (1.5h) is far past 30 minutes.
    final exponent = math.min(math.max(attemptCount, 0), 30);
    final candidateMs = math.pow(2, exponent).toInt() * 1000;
    return Duration(milliseconds: math.min(candidateMs, maxMs));
  }
}
