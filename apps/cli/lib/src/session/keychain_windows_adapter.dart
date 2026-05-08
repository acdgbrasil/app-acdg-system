/// Windows keychain adapter — DPAPI-encrypted file via PowerShell shell-out.
///
/// LIM-1 resolution (DESIGN §5): `cmdkey` cannot RETURN passwords (Windows
/// `CredRead` is not exposed to it), so we cannot use it for read. We
/// fall back to PowerShell's first-party `ConvertFrom-SecureString` /
/// `ConvertTo-SecureString` cmdlets, which ride DPAPI per-user
/// encryption. Plaintext NEVER lands on disk; the ciphertext is at
/// `%LOCALAPPDATA%\acdg\creds.dpapi`.
///
/// argv shape (no shell interpretation; secret piped via stdin):
///   powershell.exe -NoProfile -NonInteractive
///                  -ExecutionPolicy Bypass -Command `<script>`
///
/// SEC invariants:
///   * The token blob NEVER appears on argv — `[Console]::In.ReadToEnd()`
///     reads it from the child's stdin pipe.
///   * [storePath] is single-quote-validated BEFORE the runner is
///     invoked; a literal apostrophe in the path would break out of the
///     PowerShell single-quoted string and is rejected fail-fast. In
///     production [storePath] derives from `%LOCALAPPDATA%` (OS-
///     controlled) plus a constant suffix, so this branch is defense-
///     in-depth.
library;

import 'dart:convert';
import 'dart:io';

import 'package:core_contracts/core_contracts.dart';

import '../errors/cli_error.dart';
import 'keychain_adapter.dart';
import 'oidc_session.dart';

/// Windows implementation of [KeychainAdapter].
final class KeychainWindowsAdapter implements KeychainAdapter {
  KeychainWindowsAdapter({
    required this.service,
    required this.account,
    required this.storePath,
    ProcessRunner? processRunner,
  }) : _run = processRunner ?? _defaultRun;

  /// Reverse-DNS service identifier — kept on the interface for shape
  /// parity with macOS / Linux, but not embedded in the DPAPI ciphertext.
  final String service;

  /// OIDC issuer host — same shape parity remark applies.
  final String account;

  /// Absolute path to the DPAPI-encrypted file. Production wires this to
  /// `%LOCALAPPDATA%\acdg\creds.dpapi`.
  final String storePath;

  final ProcessRunner _run;

  static const String _exe = 'powershell.exe';

  /// Locked PowerShell flags — applied to every invocation.
  ///
  /// `-NoProfile` skips profile.ps1 (avoids unrelated module loads /
  /// side-effects). `-NonInteractive` causes any prompt to fail rather
  /// than hang. `-ExecutionPolicy Bypass` applies ONLY to our literal
  /// `-Command` payload (does NOT relax the system-wide policy). The
  /// final `-Command` flag immediately precedes our script string.
  static const List<String> _baseArgs = <String>[
    '-NoProfile',
    '-NonInteractive',
    '-ExecutionPolicy',
    'Bypass',
    '-Command',
  ];

  @override
  Future<Result<void>> write(OidcSession session) async {
    // SEC: defense-in-depth. The script embeds [storePath] inside a
    // PowerShell single-quoted literal. If the path contained an
    // apostrophe, the literal would close prematurely and the rest of
    // the path would be parsed as PowerShell. In production this is
    // impossible (path = `%LOCALAPPDATA%\acdg\creds.dpapi`, fully OS-
    // controlled), but we refuse fail-fast regardless — and crucially
    // we do NOT invoke the runner on the bad path.
    if (storePath.contains("'")) {
      return const Failure<void>(
        KeychainOperationFailed(0, 'invalid storePath: contains single quote'),
      );
    }
    final blob = jsonEncode(session.toJson());
    final dir = _dirOf(storePath);
    // SEC: every dynamic value (`storePath`, `dir`) is wrapped in single
    // quotes — PowerShell single-quoted literals do NOT expand variables
    // or sub-expressions, so the script body is fixed except for these
    // path strings, which we have validated above.
    final script =
        r"$tok = [Console]::In.ReadToEnd(); "
        r"$sec = ConvertTo-SecureString -String $tok -AsPlainText -Force; "
        r"$enc = ConvertFrom-SecureString -SecureString $sec; "
        "New-Item -ItemType Directory -Force -Path '$dir' | Out-Null; "
        "Set-Content -Path '$storePath' -Value \$enc -Encoding ASCII";
    try {
      // SEC: `_run` always uses `Process.start` + stdin pipe when
      // [stdinPayload] is non-null — token never on argv.
      final result = await _run(_exe, <String>[
        ..._baseArgs,
        script,
      ], stdinPayload: blob);
      if (result.exitCode == 0) return const Success<void>(null);
      return Failure<void>(
        KeychainOperationFailed(result.exitCode, _summarize(result.stderr)),
      );
      // ignore: unused_catch_stack
    } on ProcessException catch (e, st) {
      return Failure<void>(KeychainUnavailable('powershell.exe', e.message));
    }
  }

  @override
  Future<Result<OidcSession?>> read() async {
    // Cold start: file does not exist => no entry. Skip the PowerShell
    // round-trip entirely — saves a process spawn AND the test contract
    // requires zero `_run` invocations on this branch.
    if (!await File(storePath).exists()) {
      return const Success<OidcSession?>(null);
    }
    if (storePath.contains("'")) {
      return const Failure<OidcSession?>(
        KeychainOperationFailed(0, 'invalid storePath: contains single quote'),
      );
    }
    final script =
        "\$enc = Get-Content -Path '$storePath' -Raw -Encoding ASCII; "
        r"$sec = ConvertTo-SecureString -String $enc; "
        r"[System.Net.NetworkCredential]::new('', $sec).Password";
    try {
      final result = await _run(_exe, <String>[..._baseArgs, script]);
      if (result.exitCode != 0) {
        return Failure<OidcSession?>(
          KeychainOperationFailed(result.exitCode, _summarize(result.stderr)),
        );
      }
      final raw = result.stdout?.toString() ?? '';
      final blob = _trimEol(raw);
      return _decodeSession(blob);
      // ignore: unused_catch_stack
    } on ProcessException catch (e, st) {
      return Failure<OidcSession?>(
        KeychainUnavailable('powershell.exe', e.message),
      );
    }
  }

  @override
  Future<Result<void>> delete() async {
    if (storePath.contains("'")) {
      return const Failure<void>(
        KeychainOperationFailed(0, 'invalid storePath: contains single quote'),
      );
    }
    final script =
        "if (Test-Path '$storePath') { Remove-Item '$storePath' -Force }";
    try {
      // SEC: argv positional list, `runInShell: false` (default of
      // `_defaultRun`). PowerShell never echoes the script payload back.
      final result = await _run(_exe, <String>[..._baseArgs, script]);
      if (result.exitCode == 0) return const Success<void>(null);
      return Failure<void>(
        KeychainOperationFailed(result.exitCode, _summarize(result.stderr)),
      );
      // ignore: unused_catch_stack
    } on ProcessException catch (e, st) {
      return Failure<void>(KeychainUnavailable('powershell.exe', e.message));
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

  /// Trims a single trailing line ending — handles both `\r\n` (Windows
  /// PowerShell default) and `\n` (PowerShell Core on cross-platform).
  String _trimEol(String raw) {
    if (raw.endsWith('\r\n')) {
      return raw.substring(0, raw.length - 2);
    }
    if (raw.endsWith('\n')) {
      return raw.substring(0, raw.length - 1);
    }
    return raw;
  }

  /// Returns the directory component of [path] (handles both `/` and `\`).
  String _dirOf(String path) {
    final i = path.lastIndexOf(RegExp(r'[\\/]'));
    return i < 0 ? '.' : path.substring(0, i);
  }

  String _summarize(Object? stderr) {
    final text = (stderr ?? '').toString();
    return text.length > 200 ? '${text.substring(0, 200)}…' : text;
  }
}

/// Production runner — same shape as the Linux adapter's `_defaultRun`.
/// Uses `Process.start` + stdin pipe when [stdinPayload] is non-null so
/// secrets never land on argv.
Future<ProcessResult> _defaultRun(
  String exe,
  List<String> args, {
  String? stdinPayload,
}) async {
  if (stdinPayload == null) {
    // SEC: `runInShell: false` — argv reaches the child verbatim, no
    // cmd.exe / PowerShell parsing of metacharacters at the OS layer.
    return Process.run(exe, args, runInShell: false);
  }
  // SEC: stdin pipe — secret never on argv. PowerShell's
  // `[Console]::In.ReadToEnd()` reads from this pipe.
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
