/// Top-level entry point for the `acdg` CLI binary.
///
/// Wires `args.CommandRunner<int>` with:
///   * the 9 sub-commands (auth, patient, family, assessment, care,
///     protection, lookup, team, health),
///   * the global flags `--bff`, `--output`, `--quiet`,
///   * a stdout/stderr indirection so tests (and future structured-logging
///     callers) can capture I/O without poking real `Stdout`.
///
/// `CliRunner` composes a [_CapturingCommandRunner] subclass so the
/// `args` package's reflective `printUsage` / `usageException` paths land in
/// the injected sinks instead of the host process's `Stdout`. Foreign
/// callers see only the public [runner] getter typed as `CommandRunner<int>`
/// — the subclass hop is an implementation detail.
library;

import 'dart:io';
import 'dart:math';

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:http/http.dart' as http;

import 'commands/assessment_command.dart';
import 'commands/auth_command.dart';
import 'commands/auth_login_command.dart';
import 'commands/auth_logout_command.dart';
import 'commands/auth_refresh_command.dart';
import 'commands/auth_status_command.dart';
import 'commands/care_command.dart';
import 'commands/family_command.dart';
import 'commands/health_command.dart';
import 'commands/lookup_command.dart';
import 'commands/patient_command.dart';
import 'commands/protection_command.dart';
import 'errors/cli_error.dart';
import 'commands/team_command.dart';
import 'config/oidc_config.dart';
import 'oidc/loopback_listener.dart';
import 'oidc/oidc_discovery.dart';
import 'oidc/pkce_pair.dart';
import 'oidc/token_client.dart';
import 'session/credential_store.dart';

const String _executableName = 'acdg';
const String _description =
    'ACDG CLI — Operate the social care system from the command line.';
const String _defaultBffUrl = 'http://localhost:3000';

const List<String> _outputFormats = ['json', 'table', 'yaml', 'auto'];

/// Hosts the `acdg` [CommandRunner] alongside injectable I/O sinks.
///
/// Composition over inheritance: callers receive `cli.runner` typed as
/// `CommandRunner<int>` and never need to know the concrete subclass.
final class CliRunner {
  CliRunner({required StringSink stdout, required StringSink stderr})
    : _stderr = stderr {
    _runner = _CapturingCommandRunner(
      executableName: _executableName,
      description: _description,
      stdout: stdout,
    );
    _runner.argParser
      ..addOption('bff', defaultsTo: _defaultBffUrl, help: 'BFF base URL')
      ..addOption(
        'output',
        allowed: _outputFormats,
        defaultsTo: 'auto',
        help: 'json | table | yaml (default: auto — tty=table, pipe=json)',
      )
      ..addFlag(
        'quiet',
        defaultsTo: false,
        negatable: false,
        help: 'suppress info logs',
      );

    _runner
      ..addCommand(_buildAuthCommand(stdout: stdout, stderr: _stderr))
      ..addCommand(PatientCommand(stdout: stdout))
      ..addCommand(FamilyCommand(stdout: stdout))
      ..addCommand(AssessmentCommand(stdout: stdout))
      ..addCommand(CareCommand(stdout: stdout))
      ..addCommand(ProtectionCommand(stdout: stdout))
      ..addCommand(LookupCommand(stdout: stdout))
      ..addCommand(TeamCommand(stdout: stdout))
      ..addCommand(HealthCommand(stdout: stdout));
  }

  final StringSink _stderr;
  late final _CapturingCommandRunner _runner;

  /// The `args` runner — exposed typed as the parent class so foreign code
  /// cannot see the capture subclass.
  CommandRunner<int> get runner => _runner;

  /// Runs the CLI with [args], converting [UsageException] (unknown
  /// command, missing argument) into a non-zero exit code + stderr message.
  ///
  /// Other [Object]s thrown by command [Command.run] propagate unchanged
  /// (programmer faults should crash with a stack trace, per ADR-019).
  Future<int> run(List<String> args) async {
    try {
      final exitCode = await _runner.run(args);
      return exitCode ?? 0;
    } on UsageException catch (e) {
      _stderr
        ..writeln(e.message)
        ..writeln()
        ..writeln(e.usage);
      return 64; // EX_USAGE per sysexits(3).
    }
  }
}

/// `CommandRunner<int>` subclass that redirects `printUsage` to a caller-
/// supplied [StringSink] so `--help` output lands in our captured buffer
/// rather than the host process's stdout.
final class _CapturingCommandRunner extends CommandRunner<int> {
  _CapturingCommandRunner({
    required String executableName,
    required String description,
    required StringSink stdout,
  }) : _stdout = stdout,
       super(executableName, description);

  final StringSink _stdout;

  @override
  void printUsage() => _stdout.writeln(usage);
}

/// Builds the production [AuthCommand] with real collaborators wired in.
///
/// All HTTP work goes through a single shared [http.Client]; the
/// [CredentialStore] is the file-backed XDG store; the loopback listener,
/// PKCE generator, browser opener, and state/nonce factory all use real
/// production impls.
AuthCommand _buildAuthCommand({
  required StringSink stdout,
  required StringSink stderr,
}) {
  final httpClient = http.Client();
  final store = FileCredentialStore(
    path: FileCredentialStore.defaultPath(env: Platform.environment),
  );

  Future<Result<OidcDiscovery>> loadDiscovery() =>
      OidcDiscovery.load(httpClient: httpClient, issuer: OidcConfig.issuer);

  return AuthCommand(
    login: AuthLoginCommand(
      discoveryLoader: loadDiscovery,
      pkceFactory: PkcePair.generate,
      listenerFactory: ({required String expectedState}) =>
          LoopbackListener(expectedState: expectedState),
      tokenClientFactory: (discovery) =>
          TokenClient(discovery: discovery, httpClient: httpClient),
      credentialStore: store,
      browserOpener: _openBrowser,
      stateNonceFactory: _generateStateNonce,
      stdout: stdout,
      stderr: stderr,
    ),
    status: AuthStatusCommand(
      credentialStore: store,
      stdout: stdout,
      stderr: stderr,
    ),
    logout: AuthLogoutCommand(
      credentialStore: store,
      discoveryLoader: loadDiscovery,
      revoker: ({required discovery, required refreshToken}) =>
          _revokeRefreshToken(
            httpClient: httpClient,
            discovery: discovery,
            refreshToken: refreshToken,
          ),
      stdout: stdout,
      stderr: stderr,
    ),
    refresh: AuthRefreshCommand(
      credentialStore: store,
      discoveryLoader: loadDiscovery,
      tokenClientFactory: (discovery) =>
          TokenClient(discovery: discovery, httpClient: httpClient),
      stdout: stdout,
      stderr: stderr,
    ),
  );
}

/// Cross-platform "open this URL in the user's default browser".
///
/// Best-effort — failures are swallowed so the printed authorize URL
/// stays the user's recovery path. Adapter boundary (`Process.run`):
/// `try/catch` allowed here.
Future<void> _openBrowser(Uri url) async {
  try {
    if (Platform.isMacOS) {
      await Process.run('open', [url.toString()]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [url.toString()]);
    } else if (Platform.isWindows) {
      await Process.run('rundll32', [
        'url.dll,FileProtocolHandler',
        url.toString(),
      ]);
    }
  } on ProcessException {
    // Best-effort — the user can copy/paste the URL printed to stdout.
  }
}

/// 32 random bytes hex for both `state` and `nonce`. `Random.secure()`
/// in production; tests inject a deterministic factory instead.
({String state, String nonce}) _generateStateNonce() {
  final rng = Random.secure();
  String hex32() => List<int>.generate(
    32,
    (_) => rng.nextInt(256),
  ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return (state: hex32(), nonce: hex32());
}

/// Best-effort POST to the discovery `revocation_endpoint` (RFC 7009).
/// Adapter boundary — translates HTTP failures into [Result.failure].
Future<Result<void>> _revokeRefreshToken({
  required http.Client httpClient,
  required OidcDiscovery discovery,
  required String refreshToken,
}) async {
  try {
    final response = await httpClient.post(
      Uri.parse(discovery.revocationEndpoint),
      headers: const {'content-type': 'application/x-www-form-urlencoded'},
      body: <String, String>{
        'token': refreshToken,
        'token_type_hint': 'refresh_token',
        'client_id': OidcConfig.clientId,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return const Success<void>(null);
    }
    return Failure<void>(
      ServerError(
        response.statusCode,
        'revocation endpoint returned HTTP ${response.statusCode}',
      ),
    );
  } on Object catch (e, stack) {
    return Failure<void>(
      NetworkError('revoke transport failure: $e'),
      stackTrace: stack,
    );
  }
}
