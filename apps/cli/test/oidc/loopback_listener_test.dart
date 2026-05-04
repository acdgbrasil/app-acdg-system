/// W0 RED — Loopback listener defensive contract (C02 §5.5).
///
/// W1 must create `apps/cli/lib/src/oidc/loopback_listener.dart` with:
///
/// ```dart
/// /// NOT `final class` — orchestration tests in command-level suites
/// /// `implements LoopbackListener` to inject canned callback Results.
/// class LoopbackListener {
///   LoopbackListener({
///     required this.expectedState,
///     this.timeout = const Duration(minutes: 5),
///     void Function(String message)? logger,
///   });
///
///   final String expectedState;
///   final Duration timeout;
///
///   /// Binds 127.0.0.1 with port=0; returns the OS-assigned port.
///   /// Throws StateError if called twice.
///   Future<int> bindEphemeralPort();
///
///   /// Listens for /callback?code=...&state=<expected>. Filters Next.js
///   /// RSC prefetch (`_rsc=...`), CSRF state mismatches, wrong methods,
///   /// wrong paths. Closes server only on success / timeout / authorize
///   /// error. Returns Result<String> with the captured `code`.
///   Future<Result<String>> awaitCallback();
/// }
/// ```
///
/// Why a real `HttpServer` over a fake: the contract IS HTTP. Mocking it
/// would make the test prove only the mock works. Tests bind ephemeral
/// ports, drive `HttpClient` requests, assert the response and the
/// listener's internal state machine.
///
/// Logger note: tests pass an injectable `logger` capturing every line,
/// then assert the listener NEVER writes a `code=` query string into
/// the log (spike §5.5 §5.15 — codes leak in logs = audit-trail liability).
library;

import 'dart:async';
import 'dart:io';

import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:cli/src/errors/cli_error.dart';
import 'package:cli/src/oidc/loopback_listener.dart';

void main() {
  group('LoopbackListener.bindEphemeralPort', () {
    test('returns a positive port number from the loopback range', () async {
      final listener = LoopbackListener(expectedState: 'st');

      final port = await listener.bindEphemeralPort();

      expect(port, greaterThan(0));
      expect(port, lessThan(65536));
      // Cleanup — abort awaitCallback by triggering a tight timeout.
      await _drainListener(listener);
    });

    test('two listeners get different ephemeral ports', () async {
      final a = LoopbackListener(expectedState: 'a');
      final b = LoopbackListener(expectedState: 'b');

      final portA = await a.bindEphemeralPort();
      final portB = await b.bindEphemeralPort();

      expect(portA, isNot(equals(portB)));
      await _drainListener(a);
      await _drainListener(b);
    });
  });

  group('LoopbackListener.awaitCallback — happy path', () {
    test('captures code when state matches', () async {
      final listener = LoopbackListener(
        expectedState: 'st-happy',
        timeout: const Duration(seconds: 5),
      );
      final port = await listener.bindEphemeralPort();
      final futureResult = listener.awaitCallback();

      // Drive the legitimate callback.
      final response = await _get(port, '/callback?code=ABC123&state=st-happy');

      expect(response.statusCode, equals(200));
      expect(response.body.toLowerCase(), contains('login'));

      final result = await futureResult;
      expect(result, isA<Success<String>>());
      expect((result as Success<String>).value, equals('ABC123'));
    });
  });

  group('LoopbackListener — defensive filters (multi-hit)', () {
    test(
      'state empty → 204, listener KEEPS LISTENING for the real callback',
      () async {
        final listener = LoopbackListener(
          expectedState: 'st-multi',
          timeout: const Duration(seconds: 5),
        );
        final port = await listener.bindEphemeralPort();
        final futureResult = listener.awaitCallback();

        // 1st hit: empty state — RSC fantasy from Next.js. Drained.
        final drained = await _get(port, '/callback?code=PHANTOM&state=');
        expect(drained.statusCode, equals(204));

        // 2nd hit: real callback. Captured.
        final captured = await _get(port, '/callback?code=REAL&state=st-multi');
        expect(captured.statusCode, equals(200));

        final result = await futureResult;
        expect(result, isA<Success<String>>());
        expect((result as Success<String>).value, equals('REAL'));
      },
    );

    test(
      '`_rsc=...` query → 204, listener KEEPS LISTENING (RSC prefetch filter)',
      () async {
        final listener = LoopbackListener(
          expectedState: 'st-rsc',
          timeout: const Duration(seconds: 5),
        );
        final port = await listener.bindEphemeralPort();
        final futureResult = listener.awaitCallback();

        // RSC prefetch: even if state matches, `_rsc=` flips it to drop.
        final rsc = await _get(
          port,
          '/callback?code=PHANTOM&state=st-rsc&_rsc=abc123',
        );
        expect(rsc.statusCode, equals(204));

        final captured = await _get(port, '/callback?code=REAL&state=st-rsc');
        expect(captured.statusCode, equals(200));

        final result = await futureResult;
        expect(result, isA<Success<String>>());
        expect((result as Success<String>).value, equals('REAL'));
      },
    );

    test('state mismatch (CSRF) → 204, listener KEEPS LISTENING', () async {
      final listener = LoopbackListener(
        expectedState: 'st-csrf',
        timeout: const Duration(seconds: 5),
      );
      final port = await listener.bindEphemeralPort();
      final futureResult = listener.awaitCallback();

      final wrong = await _get(port, '/callback?code=ATTACKER&state=different');
      expect(wrong.statusCode, equals(204));

      final captured = await _get(port, '/callback?code=REAL&state=st-csrf');
      expect(captured.statusCode, equals(200));

      final result = await futureResult;
      expect(result, isA<Success<String>>());
      expect((result as Success<String>).value, equals('REAL'));
    });

    test('wrong path → 404, listener KEEPS LISTENING', () async {
      final listener = LoopbackListener(
        expectedState: 'st-path',
        timeout: const Duration(seconds: 5),
      );
      final port = await listener.bindEphemeralPort();
      final futureResult = listener.awaitCallback();

      final wrongPath = await _get(port, '/other?code=X&state=st-path');
      expect(wrongPath.statusCode, equals(404));

      final captured = await _get(port, '/callback?code=REAL&state=st-path');
      expect(captured.statusCode, equals(200));

      final result = await futureResult;
      expect(result, isA<Success<String>>());
      expect((result as Success<String>).value, equals('REAL'));
    });

    test('wrong method (POST) → 405, listener KEEPS LISTENING', () async {
      final listener = LoopbackListener(
        expectedState: 'st-method',
        timeout: const Duration(seconds: 5),
      );
      final port = await listener.bindEphemeralPort();
      final futureResult = listener.awaitCallback();

      final post = await _request(
        port,
        method: 'POST',
        pathAndQuery: '/callback?code=X&state=st-method',
      );
      expect(post.statusCode, equals(405));

      final captured = await _get(port, '/callback?code=REAL&state=st-method');
      expect(captured.statusCode, equals(200));

      final result = await futureResult;
      expect(result, isA<Success<String>>());
      expect((result as Success<String>).value, equals('REAL'));
    });
  });

  group('LoopbackListener — terminal failures', () {
    test(
      'authorize error (?error=access_denied) → Failure, server closes',
      () async {
        final listener = LoopbackListener(
          expectedState: 'st-err',
          timeout: const Duration(seconds: 5),
        );
        final port = await listener.bindEphemeralPort();
        final futureResult = listener.awaitCallback();

        final response = await _get(
          port,
          '/callback?error=access_denied&error_description=user+cancelled',
        );
        // Body is HTML; status code is 4xx (impl picks 400 — we accept 4xx).
        expect(response.statusCode, inInclusiveRange(400, 499));

        final result = await futureResult;
        expect(result, isA<Failure<String>>());
        final failure = result as Failure<String>;
        // Error must surface the authorize error code.
        final errStr = failure.error.toString();
        expect(errStr, contains('access_denied'));
      },
    );

    test(
      'no callback within timeout → Failure (timeout-flavored CliError)',
      () async {
        final listener = LoopbackListener(
          expectedState: 'st-timeout',
          timeout: const Duration(milliseconds: 200),
        );
        await listener.bindEphemeralPort();

        final result = await listener.awaitCallback();

        expect(result, isA<Failure<String>>());
        final failure = result as Failure<String>;
        expect(failure.error, isA<CliError>());
      },
    );
  });

  group('LoopbackListener — logging discipline (spike §5.15)', () {
    test('logger never receives raw `code=` query string', () async {
      final logs = <String>[];
      final listener = LoopbackListener(
        expectedState: 'st-log',
        timeout: const Duration(seconds: 5),
        logger: logs.add,
      );
      final port = await listener.bindEphemeralPort();
      final futureResult = listener.awaitCallback();

      // Multi-hit to exercise drop logging too.
      await _get(port, '/callback?code=DROPME&state=wrong');
      await _get(port, '/callback?code=ALSODROPME&state=st-log&_rsc=1');
      await _get(port, '/callback?code=SECRET-CAPTURED&state=st-log');

      await futureResult;

      for (final line in logs) {
        // Codes / verifiers / nonces must NEVER appear in logs.
        expect(line, isNot(contains('SECRET-CAPTURED')));
        expect(line, isNot(contains('DROPME')));
        expect(line, isNot(contains('ALSODROPME')));
        // No raw query string should leak either.
        expect(line, isNot(contains('?code=')));
        expect(line, isNot(contains('code=DROPME')));
      }
    });
  });
}

// ---------------------------------------------------------------------------
// HTTP helpers — drive the listener over real loopback. No mocks.
// ---------------------------------------------------------------------------

class _Resp {
  _Resp(this.statusCode, this.body);
  final int statusCode;
  final String body;
}

Future<_Resp> _get(int port, String pathAndQuery) =>
    _request(port, method: 'GET', pathAndQuery: pathAndQuery);

Future<_Resp> _request(
  int port, {
  required String method,
  required String pathAndQuery,
}) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse('http://127.0.0.1:$port$pathAndQuery');
    final req = await client.openUrl(method, uri);
    final res = await req.close();
    final body = await res.transform(const _Utf8Decoder()).join();
    return _Resp(res.statusCode, body);
  } finally {
    client.close(force: true);
  }
}

/// Best-effort cleanup so a bound listener does not leak past the test.
/// We don't have a public `dispose()` exposed in the contract, so we simulate
/// completion by sending the legitimate callback if the listener is still up.
/// Errors are swallowed — we only care that the OS port is freed.
Future<void> _drainListener(LoopbackListener listener) async {
  // No-op for now: the port closes when awaitCallback() resolves. Tests that
  // bind without awaiting need to call this (which currently does nothing
  // beyond signalling intent). W1 may add a `dispose()`; if so, REPORT update.
  return;
}

/// Lightweight UTF-8 stream decoder — avoids pulling in `package:convert`.
class _Utf8Decoder extends StreamTransformerBase<List<int>, String> {
  const _Utf8Decoder();

  @override
  Stream<String> bind(Stream<List<int>> stream) async* {
    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
    }
    yield String.fromCharCodes(chunks);
  }
}
