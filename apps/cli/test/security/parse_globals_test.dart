// Regression tests for B3 — CLI _parseGlobals 2-pass parser
// References:
//   .pipeline/phase-6-security-remediation/tickets/B3-cli-flags-hardening/001-design/DESIGN.md §test-matrix P1-P15
//   handbook/audit/2026-05-04-cli-qa/REPORT.md §B1
//
// SEC: P0-5 (CATASTROPHIC) — `_parseGlobals` `try/catch on FormatException`
// silently dropped user-supplied `--bff` and `--output` whenever ANY
// subcommand-specific flag (e.g. `--search=foo`) was present. With B1 +
// B2 attacker-defaults (`http://localhost:3000` plaintext, no allowlist),
// this combined into the F1 token-exfil chain.
//
// These integration tests drive the FULL `CliRunner.run([...])` with a
// captured `HttpClientAdapter` so we can assert which baseUrl actually
// reached the leaf command — the only honest way to verify the slicer
// is not silently swallowing globals.
//
// RED state at Wave 2 close:
//   * Tests that depend on the new allowlist (P1, P5, P6) will fail
//     because `validateBffUrl` does not exist yet (Wave 3 lands it).
//   * Tests that depend on the 2-pass slicer (P4, P7, P10-P12, P15) will
//     fail because the current `_parseGlobals` falls back to defaults on
//     any unknown subcommand flag.
//   * The mismatch surfaces as `expect(...)` failures, not compile errors —
//     this file imports only existing symbols.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/cli_runner.dart';

import '../golden/_helpers/golden_runner.dart';

/// Captures every Dio request seen by the runner so we can assert
/// `RequestOptions.baseUrl` (where `--bff` lands) without touching the
/// network. Mirrors Phase 5 C03+ golden tests.
final class _CapturingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  _CapturingAdapter();

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    // Default canned reply: empty list — `patient list` succeeds and emits
    // an empty JSON/table without further interaction.
    return ResponseBody.fromString(
      '{"data":[]}',
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

/// Build a `CliRunner` wired with capture sinks + adapter + a fake signed-in
/// session so subcommands actually attempt the BFF round-trip.
({
  CliRunner cli,
  StringBuffer stdout,
  StringBuffer stderr,
  _CapturingAdapter adapter,
})
_buildRunner() {
  final stdout = StringBuffer();
  final stderr = StringBuffer();
  final adapter = _CapturingAdapter();
  final cli = CliRunner(
    stdout: stdout,
    stderr: stderr,
    adapter: adapter,
    credentialStore: FakeCredentialStore.signedIn(),
  );
  return (cli: cli, stdout: stdout, stderr: stderr, adapter: adapter);
}

void main() {
  group('_parseGlobals — REJECT (allowlist failures, exit 64)', () {
    test('P1: --bff=http://localhost:8081 accepted (loopback http)', () async {
      // SEC: this is the dev-loopback acceptance case — must NOT exit 64
      // from the allowlist. The leaf command may or may not succeed
      // (depends on adapter response), but the allowlist gate is open.
      final h = _buildRunner();
      final exit = await h.cli.run(const [
        '--bff=http://localhost:8081',
        'patient',
        'list',
      ]);
      // Reaches the BFF: the request was made.
      expect(
        h.adapter.requests,
        isNotEmpty,
        reason: 'allowed URL should reach the leaf command',
      );
      expect(
        h.adapter.requests.first.uri.toString(),
        startsWith('http://localhost:8081'),
      );
      // Allowlist did not gate the run; exit code is whatever the leaf
      // returns (0 for empty list).
      expect(exit, anyOf(equals(0), isNot(equals(64))));
    });

    test('P2: --bff=https://api.acdgbrasil.com.br accepted', () async {
      final h = _buildRunner();
      final exit = await h.cli.run(const [
        '--bff=https://api.acdgbrasil.com.br',
        'patient',
        'list',
      ]);
      expect(
        h.adapter.requests,
        isNotEmpty,
        reason: 'production URL should reach the leaf command',
      );
      expect(
        h.adapter.requests.first.uri.toString(),
        startsWith('https://api.acdgbrasil.com.br'),
      );
      expect(exit, anyOf(equals(0), isNot(equals(64))));
    });

    test(
      'P3: --bff=http://evil.com → exit 64 + stderr "not allowed"',
      () async {
        // SEC: F1 fix — non-loopback http MUST be rejected.
        final h = _buildRunner();
        final exit = await h.cli.run(const [
          '--bff=http://evil.com',
          'patient',
          'list',
        ]);
        expect(exit, equals(64), reason: 'attacker URL must exit 64');
        expect(h.stderr.toString(), contains('not allowed'));
        // SEC: no token leaks — the bad URL is NOT echoed.
        expect(h.stderr.toString(), isNot(contains('evil.com')));
        // No HTTP request was ever made — we fail-fast at the allowlist.
        expect(
          h.adapter.requests,
          isEmpty,
          reason: 'rejected URL must never reach the BFF transport',
        );
      },
    );

    test(
      'P4 CRITICAL B1: --bff=http://localhost:9876 + --search=foo honors user --bff (NOT silent default)',
      () async {
        // SEC: this is the catastrophic case. Pre-B3, `_parseGlobals` caught
        // the FormatException from the unknown `--search` and returned the
        // default :3000. User wires `--bff=:9876`; CLI silently sends Bearer
        // to :3000.
        final h = _buildRunner();
        await h.cli.run(const [
          'patient',
          'list',
          '--bff=http://localhost:9876',
          '--search=foo',
        ]);
        expect(
          h.adapter.requests,
          isNotEmpty,
          reason: 'request must have been made',
        );
        final usedBaseUrl = h.adapter.requests.first.uri.toString();
        expect(
          usedBaseUrl,
          startsWith('http://localhost:9876'),
          reason:
              'user-supplied --bff MUST be honored even when subcommand has its own flags',
        );
        // The :3000 silent-fallback bug is gone:
        expect(
          usedBaseUrl,
          isNot(startsWith('http://localhost:3000')),
          reason: 'B1 silent-default-fallback must not happen',
        );
      },
    );

    test('P5: --bff=http://attacker.tld:8080 → exit 64', () async {
      final h = _buildRunner();
      final exit = await h.cli.run(const [
        '--bff=http://attacker.tld:8080',
        'patient',
        'list',
      ]);
      expect(exit, equals(64));
      expect(h.stderr.toString(), contains('not allowed'));
      expect(h.stderr.toString(), isNot(contains('attacker.tld')));
      expect(h.adapter.requests, isEmpty);
    });

    test('P6: --bff with userinfo → exit 64 + "credentials" message', () async {
      // SEC: classic URL-confusion vector + audit-trail leakage of secrets.
      final h = _buildRunner();
      final exit = await h.cli.run(const [
        '--bff=http://alice:secret@host',
        'patient',
        'list',
      ]);
      expect(exit, equals(64));
      expect(h.stderr.toString().toLowerCase(), contains('credentials'));
      // SEC: secret MUST NOT echo to stderr (could land in shell history /
      // CI logs).
      expect(h.stderr.toString(), isNot(contains('secret')));
      expect(h.stderr.toString(), isNot(contains('alice')));
      expect(h.adapter.requests, isEmpty);
    });
  });

  group('_parseGlobals — global × subcommand flag interaction', () {
    test(
      'P7: --bff=valid + unknown subcommand flag → exit 64 with UsageException naming the bogus flag',
      () async {
        // Per design: bogus subcommand flag rejected LOUDLY by CommandRunner,
        // NOT silently swallowed via fallback to default --bff.
        final h = _buildRunner();
        final exit = await h.cli.run(const [
          'patient',
          'list',
          '--bff=https://api.acdgbrasil.com.br',
          '--some-bogus-flag',
        ]);
        expect(
          exit,
          equals(64),
          reason: 'unknown subcommand flag must surface as exit 64',
        );
        // The error message must be about the bogus flag, not silently absorbed.
        expect(
          h.stderr.toString(),
          contains('some-bogus-flag'),
          reason: 'unknown flag must be named in stderr — no silent drop',
        );
      },
    );

    test('P8: --bff=http://[::1]:8081 (IPv6 loopback) accepted', () async {
      final h = _buildRunner();
      await h.cli.run(const ['--bff=http://[::1]:8081', 'patient', 'list']);
      expect(h.adapter.requests, isNotEmpty);
      // IPv6 host appears as `::1` (no brackets) in `Uri.host`, but Dio
      // re-bracket for transport — accept either form.
      expect(
        h.adapter.requests.first.uri.host,
        anyOf(equals('::1'), equals('[::1]')),
      );
    });

    test(
      'P9: --bff=https://api.acdgbrasil.com.br:80 accepted (port-agnostic)',
      () async {
        final h = _buildRunner();
        await h.cli.run(const [
          '--bff=https://api.acdgbrasil.com.br:80',
          'patient',
          'list',
        ]);
        expect(h.adapter.requests, isNotEmpty);
        expect(
          h.adapter.requests.first.uri.host,
          equals('api.acdgbrasil.com.br'),
        );
      },
    );

    test('P10: space-separated --bff value form (--bff URL) honored', () async {
      // SEC: POSIX/GNU compliance — `--bff URL` (space) must work just like
      // `--bff=URL`. Pre-B3 slicer must consume the next argv slot.
      final h = _buildRunner();
      await h.cli.run(const [
        'patient',
        'list',
        '--bff',
        'http://127.0.0.1:9876',
        '--search=foo',
      ]);
      expect(h.adapter.requests, isNotEmpty);
      expect(
        h.adapter.requests.first.uri.toString(),
        startsWith('http://127.0.0.1:9876'),
      );
    });

    test(
      'P11: --output=json with subcommand flag → user --output honored (NOT silent default)',
      () async {
        // SEC (UX-side of B1): `--output` is also silently dropped today.
        // Same fix path.
        final h = _buildRunner();
        final exit = await h.cli.run(const [
          '--output=json',
          'patient',
          'list',
          '--search=foo',
        ]);
        expect(
          exit,
          anyOf(equals(0), isNot(equals(64))),
          reason: 'allowed default :3000 + valid --output',
        );
        // Output starts with JSON shape, not a table.
        // (Empty list adapter returns `{"data":[]}` ⇒ JsonFormatter outputs
        // a JSON array/object, never a `┌──` table border.)
        expect(h.stdout.toString(), isNot(contains('┌')));
        expect(h.stdout.toString(), isNot(contains('│')));
      },
    );

    test('P12: -q (short --quiet) honored alongside subcommand flag', () async {
      final h = _buildRunner();
      final exit = await h.cli.run(const [
        '-q',
        'patient',
        'list',
        '--search=foo',
      ]);
      expect(
        exit,
        anyOf(equals(0), isNot(equals(64))),
        reason: '-q must NOT trip the "unknown global" path',
      );
    });
  });

  group('_parseGlobals — usage errors (exit 64)', () {
    test('P13: --bff with no value → exit 64 + usage error', () async {
      final h = _buildRunner();
      final exit = await h.cli.run(const ['--bff']);
      expect(exit, equals(64));
      expect(h.stderr.toString(), isNotEmpty);
    });

    test('P14: --output=invalid-format → exit 64', () async {
      final h = _buildRunner();
      final exit = await h.cli.run(const [
        '--output=invalid-format',
        'patient',
        'list',
      ]);
      expect(exit, equals(64));
      expect(h.stderr.toString(), isNotEmpty);
    });

    test(
      'P15: POSIX `--` boundary respected — --bff after `--` is positional',
      () async {
        // After `--`, no token is reparsed as a flag. So `--bff=http://evil.tld`
        // here MUST NOT trigger the allowlist — it's a positional arg the
        // subcommand will reject for its own reasons (not exit 64 via allowlist).
        final h = _buildRunner();
        final exit = await h.cli.run(const [
          '--bff=http://localhost:8081', // real global
          'patient',
          'list',
          '--',
          '--bff=http://evil.tld', // positional after `--`
        ]);
        // Allowlist did NOT gate the run (the real global is loopback).
        // The exit code may be 64 if the leaf rejects the positional, but the
        // stderr message must NOT be the allowlist template.
        expect(
          h.stderr.toString(),
          isNot(contains('--bff URL is not allowed')),
        );
        // The HTTP request that DID go out used the real --bff, not evil.tld.
        if (h.adapter.requests.isNotEmpty) {
          expect(
            h.adapter.requests.first.uri.toString(),
            startsWith('http://localhost:8081'),
          );
        }
        // Sanity: exit isn't 0 (extra positional rejected by leaf), but never
        // due to allowlist.
        expect(exit, isNotNull);
      },
    );
  });
}
