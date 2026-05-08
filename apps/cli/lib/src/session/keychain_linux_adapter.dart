/// Linux keychain adapter — `secret-tool` (libsecret-tools) shell-out.
///
/// Critical difference vs. macOS: `secret-tool store` reads the secret
/// from STDIN, never argv — so `ps -ef` / `/proc/<pid>/cmdline` cannot
/// disclose the JSON blob.
///
/// argv shapes (no shell, no interpolation):
///   write:  secret-tool store --label='ACDG CLI' service `<service>`
///                                                 account `<account>`
///           (blob piped via stdin; EOF terminates)
///   read:   secret-tool lookup service `<service>` account `<account>`
///   delete: secret-tool clear  service `<service>` account `<account>`
library;

import 'dart:convert';
import 'dart:io';

import 'package:core_contracts/core_contracts.dart';

import '../errors/cli_error.dart';
import 'keychain_adapter.dart';
import 'oidc_session.dart';

/// Linux implementation of [KeychainAdapter].
final class KeychainLinuxAdapter implements KeychainAdapter {
  KeychainLinuxAdapter({
    required this.service,
    required this.account,
    ProcessRunner? processRunner,
  }) : _run = processRunner ?? _defaultRun;

  final String service;
  final String account;
  final ProcessRunner _run;

  static const String _exe = 'secret-tool';
  static const String _label = 'ACDG CLI';

  /// Operator-friendly hint surfaced inside [KeychainUnavailable] when
  /// `secret-tool` is missing. Covers the three majority distros.
  static const String _installHint =
      'Install libsecret-tools: '
      'apt install libsecret-tools (Debian/Ubuntu) | '
      'dnf install libsecret (Fedora) | '
      'pacman -S libsecret (Arch).';

  @override
  Future<Result<void>> write(OidcSession session) async {
    final blob = jsonEncode(session.toJson());
    try {
      // SEC: stdinPayload — secret reaches the child via stdin pipe,
      // NEVER argv. The `_defaultRun` impl uses `Process.start` +
      // stdin.write + stdin.close to honour this contract.
      final result = await _run(_exe, <String>[
        'store',
        '--label=$_label',
        'service',
        service,
        'account',
        account,
      ], stdinPayload: blob);
      if (result.exitCode == 0) return const Success<void>(null);
      return Failure<void>(
        KeychainOperationFailed(result.exitCode, _summarize(result.stderr)),
      );
    } on ProcessException {
      return const Failure<void>(KeychainUnavailable(_exe, _installHint));
    }
  }

  @override
  Future<Result<OidcSession?>> read() async {
    try {
      // SEC: lookup needs no stdin — argv-only invocation.
      final result = await _run(_exe, <String>[
        'lookup',
        'service',
        service,
        'account',
        account,
      ]);
      if (result.exitCode == 1) {
        // `secret-tool lookup` returns exit 1 when the entry is absent.
        return const Success<OidcSession?>(null);
      }
      if (result.exitCode != 0) {
        return Failure<OidcSession?>(
          KeychainOperationFailed(result.exitCode, _summarize(result.stderr)),
        );
      }
      final raw = result.stdout?.toString() ?? '';
      final blob = raw.endsWith('\n') ? raw.substring(0, raw.length - 1) : raw;
      if (blob.isEmpty) return const Success<OidcSession?>(null);
      return _decodeSession(blob);
    } on ProcessException {
      return const Failure<OidcSession?>(
        KeychainUnavailable(_exe, _installHint),
      );
    }
  }

  @override
  Future<Result<void>> delete() async {
    try {
      // SEC: argv positional list — no shell, no interpolation.
      final result = await _run(_exe, <String>[
        'clear',
        'service',
        service,
        'account',
        account,
      ]);
      if (result.exitCode == 0) return const Success<void>(null);
      return Failure<void>(
        KeychainOperationFailed(result.exitCode, _summarize(result.stderr)),
      );
    } on ProcessException {
      return const Failure<void>(KeychainUnavailable(_exe, _installHint));
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

  String _summarize(Object? stderr) {
    final text = (stderr ?? '').toString();
    return text.length > 200 ? '${text.substring(0, 200)}…' : text;
  }
}

/// Production runner — uses `Process.start` (NOT `Process.run`) when a
/// [stdinPayload] is provided so the secret reaches the binary via pipe.
///
/// SEC: `runInShell: false` — argv reaches the child verbatim via
/// execve(2); no shell parses metacharacters. When [stdinPayload] is
/// non-null, the secret is written to the child's stdin and stdin is
/// closed before we await stdout/stderr collection.
Future<ProcessResult> _defaultRun(
  String exe,
  List<String> args, {
  String? stdinPayload,
}) async {
  if (stdinPayload == null) {
    return Process.run(exe, args, runInShell: false);
  }
  // SEC: stdin pipe — the secret never lands on argv, even if the binary
  // were to dump its argv on failure (which secret-tool does not).
  final process = await Process.start(exe, args, runInShell: false);
  process.stdin.write(stdinPayload);
  await process.stdin.close();
  final stdoutFuture = process.stdout.transform(utf8.decoder).join();
  final stderrFuture = process.stderr.transform(utf8.decoder).join();
  final exitCode = await process.exitCode;
  return ProcessResult(
    process.pid,
    exitCode,
    await stdoutFuture,
    await stderrFuture,
  );
}
