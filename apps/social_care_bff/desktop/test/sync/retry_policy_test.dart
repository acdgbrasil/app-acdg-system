/// RED-phase tests for `RetryPolicy` (A18a-v2).
///
/// `RetryPolicy` encapsulates the exponential-backoff math used by
/// `SyncEngine` when scheduling retries of `failed_retriable` mutations.
/// It is a pure value type — no I/O, no time injection — fully tested
/// from the math alone.
///
/// ── Surface under test ────────────────────────────────────────────────
///   * `RetryPolicy({int maxAttempts, Duration maxDelay})` — defaults
///     `maxAttempts = 10`, `maxDelay = const Duration(minutes: 30)`.
///   * `bool shouldRetry(int attemptCount)` — true while `attemptCount <
///     maxAttempts`; false otherwise.
///   * `Duration nextDelay(int attemptCount)` — `2^attemptCount` seconds,
///     capped at `maxDelay`.
///
/// ── Test axes ────────────────────────────────────────────────────────
///   1. Default constructor produces the documented defaults.
///   2. shouldRetry boundary at `maxAttempts`.
///   3. nextDelay grows exponentially from attemptCount = 0.
///   4. nextDelay never exceeds `maxDelay` even at very large counts.
///   5. attemptCount = 0 yields the smallest delay (1 second).
///   6. Custom config (small maxAttempts / small maxDelay) is honored.
///
/// IMPORTANT (RED phase): `RetryPolicy` does NOT exist yet. The `import`
/// line fails — that is the intended RED signal. W1 implements it at
/// `lib/src/sync/engine/retry_policy.dart`.
library;

import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/sync/engine/retry_policy.dart';

void main() {
  group('RetryPolicy defaults', () {
    test('default constructor: maxAttempts = 10, maxDelay = 30 minutes', () {
      const policy = RetryPolicy();
      expect(policy.maxAttempts, 10);
      expect(policy.maxDelay, const Duration(minutes: 30));
    });
  });

  group('RetryPolicy.shouldRetry', () {
    test('returns true for attemptCount < maxAttempts', () {
      const policy = RetryPolicy();
      for (var i = 0; i < 10; i++) {
        expect(
          policy.shouldRetry(i),
          isTrue,
          reason: 'attemptCount=$i should retry under default maxAttempts=10',
        );
      }
    });

    test('returns false at maxAttempts boundary', () {
      const policy = RetryPolicy();
      expect(policy.shouldRetry(10), isFalse);
      expect(policy.shouldRetry(11), isFalse);
      expect(policy.shouldRetry(99), isFalse);
    });
  });

  group('RetryPolicy.nextDelay (math)', () {
    test('attemptCount = 0 yields 1 second (2^0)', () {
      const policy = RetryPolicy();
      expect(policy.nextDelay(0), const Duration(seconds: 1));
    });

    test('grows exponentially: 1s, 2s, 4s, 8s, 16s, 32s', () {
      const policy = RetryPolicy();
      expect(policy.nextDelay(0), const Duration(seconds: 1));
      expect(policy.nextDelay(1), const Duration(seconds: 2));
      expect(policy.nextDelay(2), const Duration(seconds: 4));
      expect(policy.nextDelay(3), const Duration(seconds: 8));
      expect(policy.nextDelay(4), const Duration(seconds: 16));
      expect(policy.nextDelay(5), const Duration(seconds: 32));
    });

    test('never exceeds maxDelay even at very high attemptCount', () {
      const policy = RetryPolicy();
      // 2^60 seconds is astronomical — must clamp at 30 minutes.
      expect(policy.nextDelay(60), const Duration(minutes: 30));
      expect(policy.nextDelay(1000), const Duration(minutes: 30));
    });

    test('caps somewhere between attemptCount=10 and attemptCount=12', () {
      // 2^10 = 1024s ≈ 17min  → not yet capped
      // 2^11 = 2048s ≈ 34min  → capped at 30min
      const policy = RetryPolicy();
      expect(policy.nextDelay(10), const Duration(seconds: 1024));
      expect(policy.nextDelay(11), const Duration(minutes: 30));
      expect(policy.nextDelay(12), const Duration(minutes: 30));
    });
  });

  group('RetryPolicy custom config', () {
    test('custom maxAttempts = 3 honored by shouldRetry', () {
      const policy = RetryPolicy(maxAttempts: 3);
      expect(policy.shouldRetry(0), isTrue);
      expect(policy.shouldRetry(2), isTrue);
      expect(policy.shouldRetry(3), isFalse);
      expect(policy.shouldRetry(4), isFalse);
    });

    test('custom maxDelay = 10s caps nextDelay early', () {
      const policy = RetryPolicy(maxDelay: Duration(seconds: 10));
      expect(policy.nextDelay(0), const Duration(seconds: 1));
      expect(policy.nextDelay(1), const Duration(seconds: 2));
      expect(policy.nextDelay(2), const Duration(seconds: 4));
      expect(policy.nextDelay(3), const Duration(seconds: 8));
      // 2^4 = 16s > 10s cap.
      expect(policy.nextDelay(4), const Duration(seconds: 10));
      expect(policy.nextDelay(20), const Duration(seconds: 10));
    });
  });
}
