/// macOS keychain adapter — `/usr/bin/security` shell-out to the login
/// keychain.
///
/// argv shapes (no shell, no interpolation):
///   write:  security add-generic-password -U -s `<service>` -a `<account>`
///                                          -w `<blob>`
///   read:   security find-generic-password -s `<service>` -a `<account>` -w
///   delete: security delete-generic-password -s `<service>` -a `<account>`
///
/// LIM-2 (DESIGN §LIM-2 + §3): `-w blob` puts the secret in argv,
/// visible in `ps -A` for the child's lifetime (~10 ms). Accepted
/// tradeoff vs. persistent plaintext: `security` has NO non-interactive
/// stdin path for `add-generic-password`. Documented in the ticket.
library;

import 'dart:convert';
import 'dart:io';

import 'package:core_contracts/core_contracts.dart';

import '../errors/cli_error.dart';
import 'keychain_adapter.dart';
import 'oidc_session.dart';

/// macOS implementation of [KeychainAdapter].
final class KeychainMacosAdapter implements KeychainAdapter {
  KeychainMacosAdapter({
    required this.service,
    required this.account,
    ProcessRunner? processRunner,
  }) : _run = processRunner ?? _defaultRun;

  final String service;
  final String account;
  final ProcessRunner _run;

  /// Absolute path to the `security` binary. Always present on macOS;
  /// hard-coded so `$PATH` poisoning cannot redirect the call.
  static const String _exe = '/usr/bin/security';

  /// `errSecItemNotFound` — the canonical "no entry" exit code that both
  /// `find-generic-password` and `delete-generic-password` use. Treated
  /// as a non-error in `read` (cold start) and `delete` (idempotent).
  static const int _errSecItemNotFound = 44;

  @override
  Future<Result<void>> write(OidcSession session) async {
    final blob = jsonEncode(session.toJson());
    try {
      // SEC: `Process.run(exe, [args])` — argv is a positional list, no
      // shell parses it. `-U` upserts so we never race a separate
      // delete+add pair. `-w <blob>` is the LAST positional (LIM-2).
      final result = await _run(_exe, <String>[
        'add-generic-password',
        '-U',
        '-s',
        service,
        '-a',
        account,
        '-w',
        blob,
      ]);
      if (result.exitCode == 0) return const Success<void>(null);
      return Failure<void>(
        KeychainOperationFailed(result.exitCode, _summarize(result.stderr)),
      );
      // ignore: unused_catch_stack
    } on ProcessException catch (e, st) {
      // Should never happen — `security` ships with macOS — but the
      // failure mode must still translate to `Result`.
      return Failure<void>(KeychainUnavailable('security', e.message));
    }
  }

  @override
  Future<Result<OidcSession?>> read() async {
    try {
      // SEC: argv has no secret here — `-w` (the *flag*) instructs
      // `security` to print the password to stdout. The user's blob is
      // never on argv during read.
      final result = await _run(_exe, <String>[
        'find-generic-password',
        '-s',
        service,
        '-a',
        account,
        '-w',
      ]);
      if (result.exitCode == _errSecItemNotFound) {
        return const Success<OidcSession?>(null);
      }
      if (result.exitCode != 0) {
        return Failure<OidcSession?>(
          KeychainOperationFailed(result.exitCode, _summarize(result.stderr)),
        );
      }
      // SEC: stdout from `-w` is the password literal followed by exactly
      // one '\n'. Trim ONE trailing newline only — must NOT strip JSON
      // whitespace (would corrupt blobs that legitimately contain it).
      final raw = result.stdout?.toString() ?? '';
      final blob = raw.endsWith('\n') ? raw.substring(0, raw.length - 1) : raw;
      return _decodeSession(blob);
      // ignore: unused_catch_stack
    } on ProcessException catch (e, st) {
      return Failure<OidcSession?>(KeychainUnavailable('security', e.message));
    }
  }

  @override
  Future<Result<void>> delete() async {
    try {
      // SEC: `Process.run(exe, [args])` — argv positional, no shell.
      final result = await _run(_exe, <String>[
        'delete-generic-password',
        '-s',
        service,
        '-a',
        account,
      ]);
      // exit 0 = deleted; exit 44 = not found (idempotent).
      if (result.exitCode == 0 || result.exitCode == _errSecItemNotFound) {
        return const Success<void>(null);
      }
      return Failure<void>(
        KeychainOperationFailed(result.exitCode, _summarize(result.stderr)),
      );
      // ignore: unused_catch_stack
    } on ProcessException catch (e, st) {
      return Failure<void>(KeychainUnavailable('security', e.message));
    }
  }

  /// Decodes [blob] into an [OidcSession]; surfaces [KeychainCorruptEntry]
  /// on JSON-parse / wrong-shape / `OidcSession.fromJson` failure.
  Result<OidcSession?> _decodeSession(String blob) {
    try {
      final decoded = jsonDecode(blob);
      if (decoded is! Map<String, Object?>) {
        return const Failure<OidcSession?>(KeychainCorruptEntry());
      }
      return Success<OidcSession?>(OidcSession.fromJson(decoded));
    } on FormatException {
      return const Failure<OidcSession?>(KeychainCorruptEntry());
    }
  }

  /// Truncates stderr to a fixed length so a runaway stderr cannot
  /// dominate the user's terminal. The secret blob never appears in
  /// stderr (binary never reads it on failure paths; never echoes it on
  /// success paths).
  String _summarize(Object? stderr) {
    final text = (stderr ?? '').toString();
    return text.length > 200 ? '${text.substring(0, 200)}…' : text;
  }
}

/// Production runner — `Process.run` with `runInShell: false` (the Dart
/// default; pinned explicit for the reader). macOS path never needs
/// stdin, so [stdinPayload] is ignored.
Future<ProcessResult> _defaultRun(
  String exe,
  List<String> args, {
  String? stdinPayload,
}) {
  // SEC: `runInShell: false` — argv is delivered to the child verbatim
  // via the OS exec-family syscall. No shell parses metacharacters.
  return Process.run(exe, args, runInShell: false);
}
