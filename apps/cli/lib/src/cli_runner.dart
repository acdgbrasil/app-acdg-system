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
///
/// C10 additions:
///   * Optional `adapter` (`HttpClientAdapter`) — when supplied, every BFF
///     call goes through this adapter instead of the production Dio
///     transport. Lets golden tests replay canned responses without spinning
///     up a real HTTP server.
///   * Optional `credentialStore` (`CredentialStore`) — when supplied,
///     replaces the default `FileCredentialStore` (XDG path), so golden
///     tests can inject a synthetic "signed-in"/"signed-out" session
///     without touching disk.
///   * `--output` is finally honored at the runner level: each `run()`
///     parses the global flag, calls `resolveFormatter`, and rebuilds the
///     leaf commands with the chosen formatter.
///   * `--bff` is wired into the [BffClient] base URL on a per-`run()`
///     basis so callers can target staging/production without restarting
///     the CLI.
library;

import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import 'commands/assessment_command.dart';
import 'commands/assessment_community_support_command.dart';
import 'commands/assessment_education_command.dart';
import 'commands/assessment_health_command.dart';
import 'commands/assessment_housing_command.dart';
import 'commands/assessment_social_health_summary_command.dart';
import 'commands/assessment_socioeconomic_command.dart';
import 'commands/assessment_work_income_command.dart';
import 'commands/auth_command.dart';
import 'commands/auth_login_command.dart';
import 'commands/auth_logout_command.dart';
import 'commands/auth_refresh_command.dart';
import 'commands/auth_status_command.dart';
import 'commands/care_appointment_command.dart';
import 'commands/care_command.dart';
import 'commands/care_intake_command.dart';
import 'commands/family_add_command.dart';
import 'commands/family_assign_caregiver_command.dart';
import 'commands/family_command.dart';
import 'commands/family_remove_command.dart';
import 'commands/family_update_identity_command.dart';
import 'commands/health_command.dart';
import 'commands/lookup_batch_command.dart';
import 'commands/lookup_command.dart';
import 'commands/lookup_create_command.dart';
import 'commands/lookup_get_command.dart';
import 'commands/lookup_request_approve_command.dart';
import 'commands/lookup_request_command.dart';
import 'commands/lookup_request_create_command.dart';
import 'commands/lookup_request_list_command.dart';
import 'commands/lookup_request_reject_command.dart';
import 'commands/lookup_toggle_command.dart';
import 'commands/lookup_update_command.dart';
import 'commands/patient_admit_command.dart';
import 'commands/patient_audit_command.dart';
import 'commands/patient_command.dart';
import 'commands/patient_discharge_command.dart';
import 'commands/patient_get_command.dart';
import 'commands/patient_list_command.dart';
import 'commands/patient_readmit_command.dart';
import 'commands/patient_register_command.dart';
import 'commands/patient_withdraw_command.dart';
import 'commands/protection_command.dart';
import 'commands/protection_placement_history_command.dart';
import 'commands/protection_referral_command.dart';
import 'commands/protection_violation_command.dart';
import 'commands/team_command.dart';
import 'commands/team_deactivate_command.dart';
import 'commands/team_get_command.dart';
import 'commands/team_list_command.dart';
import 'commands/team_reactivate_command.dart';
import 'commands/team_register_command.dart';
import 'commands/team_reset_password_command.dart';
import 'commands/team_role_assign_command.dart';
import 'commands/team_role_command.dart';
import 'commands/team_role_deactivate_command.dart';
import 'commands/team_role_reactivate_command.dart';
import 'config/bff_allowlist.dart';
import 'config/oidc_config.dart';
import 'errors/cli_error.dart';
import 'formatters/auto_formatter.dart';
import 'formatters/output_formatter.dart';
import 'oidc/loopback_listener.dart';
import 'oidc/oidc_discovery.dart';
import 'oidc/pkce_pair.dart';
import 'oidc/token_client.dart';
import 'session/bff_client.dart';
import 'session/credential_store.dart';
import 'session/credential_store_factory.dart';
import 'session/oidc_session.dart';

const String _executableName = 'acdg';
const String _description =
    'ACDG CLI — Operate the social care system from the command line.';
const String _defaultBffUrl = 'http://localhost:3000';

const List<String> _outputFormats = ['json', 'table', 'yaml', 'auto'];

/// Hosts the `acdg` [CommandRunner] alongside injectable I/O sinks.
///
/// Composition over inheritance: callers receive `cli.runner` typed as
/// `CommandRunner<int>` and never need to know the concrete subclass.
///
/// **Per-run rebuild policy.** Leaf commands (`PatientListCommand`, …) take
/// `OutputFormatter` and `BffClient` as constructor params, so resolving
/// `--output` (and `--bff`) at the runner level requires re-instantiating
/// them. Each [run] call therefore:
///   1. Parses `--output` and `--bff` from [args] using a side `ArgParser`
///      that mirrors the global flag set.
///   2. Picks an [OutputFormatter] via [resolveFormatter] (auto detection
///      uses the actual stdout sink — `StringBuffer` ⇒ pipe ⇒ JSON).
///   3. Builds a fresh [_CapturingCommandRunner] with all 9 sub-commands
///      wired against the chosen formatter and BFF base URL.
///   4. Dispatches to that fresh runner.
///
/// The eager `_runner` built in the constructor stays around so [runner]
/// (used by `--help` test discovery and `cli_runner_test.dart`) remains
/// non-null with the auto-defaulted formatter and the default BFF base URL.
/// Production callers go through [run] directly, so the eager build is
/// effectively only paid once and only matters for test surfaces.
final class CliRunner {
  CliRunner({
    required StringSink stdout,
    required StringSink stderr,
    HttpClientAdapter? adapter,
    CredentialStore? credentialStore,
    DateTime Function()? clock,
  }) : _stdout = stdout,
       _stderr = stderr,
       _adapter = adapter,
       _clock = clock,
       _httpClient = http.Client() {
    if (credentialStore != null) {
      _credentialStore = credentialStore;
    } else {
      // B4 — production credential storage routes through the system
      // keychain (Keychain.app on macOS, libsecret on Linux, DPAPI via
      // PowerShell on Windows). The legacy plaintext file at
      // `$XDG_CONFIG_HOME/acdg/credentials` is consulted only by the
      // migration shim (read-once-then-delete after read-after-write
      // verification). See B4 DESIGN.md §6-§7.
      final result = CredentialStoreFactory.createSync(
        env: Platform.environment,
      );
      switch (result) {
        case Success<CredentialStore>(:final value):
          _credentialStore = value;
        case Failure<CredentialStore>(:final error):
          // SEC: no silent fallback to plaintext. Surface the install
          // hint and use a stub store that returns null on every read so
          // the next BFF call cleanly surfaces `AuthRequiredError`.
          stderr.writeln('acdg: credential storage unavailable — $error');
          _credentialStore = const _UnavailableCredentialStore();
      }
    }
    _runner = _assemble(
      formatter: resolveFormatter(
        explicitFormat: null,
        isTerminal: _stdoutHasTerminal(stdout),
      ),
      baseUrl: _defaultBffUrl,
    );
  }

  final StringSink _stdout;
  final StringSink _stderr;
  final HttpClientAdapter? _adapter;
  final DateTime Function()? _clock;
  final http.Client _httpClient;
  late final CredentialStore _credentialStore;
  late _CapturingCommandRunner _runner;

  /// The `args` runner — exposed typed as the parent class so foreign code
  /// cannot see the capture subclass.
  ///
  /// Reflects the constructor-time wiring (auto-resolved formatter, default
  /// BFF URL). Foreign callers (the binary entrypoint, golden tests) drive
  /// the CLI through [run], which always rebuilds with the per-invocation
  /// `--output` / `--bff` values.
  CommandRunner<int> get runner => _runner;

  /// Runs the CLI with [args], converting [UsageException] (unknown
  /// command, missing argument) into a non-zero exit code + stderr message.
  ///
  /// Other [Object]s thrown by command [Command.run] propagate unchanged
  /// (programmer faults should crash with a stack trace, per ADR-019).
  ///
  /// Re-instantiates the assembled runner per invocation so `--output` and
  /// `--bff` propagate to every leaf command.
  Future<int> run(List<String> args) async {
    // B4 — run the legacy-file → keychain migration shim once per CLI
    // invocation, before any subcommand can reach the credential store.
    // Idempotent and best-effort: failures leave the legacy file in
    // place and surface a stderr warning at next operation.
    await _migrateOnce();

    // SEC: every `run` invocation flows through `_parseGlobals`, which gates
    // every BFF URL (explicit `--bff` AND the bake-in default) through
    // `validateBffUrl`. Defense-in-depth: a malicious `--dart-define=ACDG_BFF_URL`
    // build OR a hostile `--bff` flag both fail-fast at exit 64.
    final parsed = _parseGlobals(args);
    final _GlobalFlags globals;
    switch (parsed) {
      case _GlobalsOk(:final value):
        globals = value;
      case _GlobalsUsage(:final message):
        _stderr.writeln('error: $message');
        return 64; // EX_USAGE
      case _GlobalsBff(:final error):
        _stderr.writeln(renderBffAllowlistError(error));
        return 64; // SEC: F1 mitigation — EX_USAGE per sysexits(3).
    }
    final OutputFormatter formatter;
    try {
      formatter = resolveFormatter(
        explicitFormat: globals.output,
        isTerminal: _stdoutHasTerminal(_stdout),
      );
      // ignore: unused_catch_stack
    } on InvalidArgError catch (e, st) {
      _stderr.writeln(e.message);
      return 64;
    }
    final assembled = _assemble(formatter: formatter, baseUrl: globals.bffUrl);
    _runner = assembled;
    try {
      final exitCode = await assembled.run(args);
      return exitCode ?? 0;
      // ignore: unused_catch_stack
    } on UsageException catch (e, st) {
      _stderr
        ..writeln(e.message)
        ..writeln()
        ..writeln(e.usage);
      return 64; // EX_USAGE per sysexits(3).
    }
  }

  /// Tracks whether the migration shim has already run for this
  /// instance. Migration is one-shot per CLI invocation.
  bool _migrated = false;

  /// Runs the B4 migration shim at most once. No-op when an explicit
  /// [CredentialStore] was injected (test fixtures bypass migration).
  Future<void> _migrateOnce() async {
    if (_migrated) return;
    _migrated = true;
    if (_credentialStore is! KeychainCredentialStore) {
      // Either an injected fake (tests) or the [_UnavailableCredentialStore]
      // fallback — neither path benefits from migration.
      return;
    }
    await CredentialStoreFactory.migrateLegacyOnce(env: Platform.environment);
  }

  /// Builds a fresh [_CapturingCommandRunner] with all nine sub-commands
  /// wired against the supplied [formatter] and [baseUrl]. Used both by
  /// the constructor (default formatter / URL) and by [run] (per-invocation
  /// resolved values).
  _CapturingCommandRunner _assemble({
    required OutputFormatter formatter,
    required String baseUrl,
  }) {
    final assembled = _CapturingCommandRunner(
      executableName: _executableName,
      description: _description,
      stdout: _stdout,
    );
    assembled.argParser
      ..addOption('bff', defaultsTo: _defaultBffUrl, help: 'BFF base URL')
      ..addOption(
        'output',
        allowed: _outputFormats,
        defaultsTo: 'auto',
        help: 'json | table | yaml (default: auto — tty=table, pipe=json)',
      )
      ..addFlag(
        'quiet',
        abbr: 'q',
        defaultsTo: false,
        negatable: false,
        help: 'suppress info logs',
      );

    Future<Result<OidcDiscovery>> loadDiscovery() =>
        OidcDiscovery.load(httpClient: _httpClient, issuer: OidcConfig.issuer);

    final bffClient = _buildBffClient(
      baseUrl: baseUrl,
      credentialStore: _credentialStore,
      adapter: _adapter,
    );

    assembled
      ..addCommand(
        _buildAuthCommand(
          httpClient: _httpClient,
          credentialStore: _credentialStore,
          loadDiscovery: loadDiscovery,
          stdout: _stdout,
          stderr: _stderr,
          clock: _clock,
        ),
      )
      ..addCommand(
        _buildPatientCommand(
          bffClient: bffClient,
          formatter: formatter,
          stdout: _stdout,
          stderr: _stderr,
        ),
      )
      ..addCommand(
        _buildFamilyCommand(
          bffClient: bffClient,
          formatter: formatter,
          stdout: _stdout,
          stderr: _stderr,
        ),
      )
      ..addCommand(
        _buildAssessmentCommand(
          bffClient: bffClient,
          formatter: formatter,
          stdout: _stdout,
          stderr: _stderr,
        ),
      )
      ..addCommand(
        _buildCareCommand(
          bffClient: bffClient,
          formatter: formatter,
          stdout: _stdout,
          stderr: _stderr,
        ),
      )
      ..addCommand(
        _buildProtectionCommand(
          bffClient: bffClient,
          formatter: formatter,
          stdout: _stdout,
          stderr: _stderr,
        ),
      )
      ..addCommand(
        _buildLookupCommand(
          bffClient: bffClient,
          formatter: formatter,
          stdout: _stdout,
          stderr: _stderr,
        ),
      )
      ..addCommand(
        _buildTeamCommand(
          bffClient: bffClient,
          formatter: formatter,
          stdout: _stdout,
          stderr: _stderr,
        ),
      )
      ..addCommand(HealthCommand(stdout: _stdout));
    return assembled;
  }
}

/// Parsed view of the global flags read out of `argv` BEFORE the assembled
/// runner sees them. The runner re-parses for the leaf command; this side
/// parse is purely about deciding which formatter / BFF URL to wire into
/// the leaf command constructors.
final class _GlobalFlags {
  const _GlobalFlags({required this.output, required this.bffUrl});
  final String? output;
  final String bffUrl;
}

/// Recognised long-form global flag names — single source of truth, must
/// match the keys registered on the assembled `CommandRunner`'s argParser.
const Set<String> _globalLongFlags = {'bff', 'output', 'quiet'};

/// Recognised short-form global flag letters (`-q` aliases `--quiet`).
const Set<String> _globalShortFlags = {'q'};

/// Long-form global names that take a VALUE (option-style). Distinguishes
/// `--bff URL` (consume next argv slot) from `--quiet` (boolean, no value).
const Set<String> _globalLongOptions = {'bff', 'output'};

/// Discriminated union returned by [_parseGlobals]: ok / usage error /
/// allowlist rejection. Keeps [CliRunner.run] linear (no exceptions).
sealed class _GlobalsOrError {
  const _GlobalsOrError();
  factory _GlobalsOrError.ok(_GlobalFlags g) = _GlobalsOk;
  factory _GlobalsOrError.usage(String msg) = _GlobalsUsage;
  factory _GlobalsOrError.bff(BffAllowlistError e) = _GlobalsBff;
}

final class _GlobalsOk extends _GlobalsOrError {
  const _GlobalsOk(this.value);
  final _GlobalFlags value;
}

final class _GlobalsUsage extends _GlobalsOrError {
  const _GlobalsUsage(this.message);
  final String message;
}

final class _GlobalsBff extends _GlobalsOrError {
  const _GlobalsBff(this.error);
  final BffAllowlistError error;
}

/// 2-pass global-flag parser.
///
/// Pass A — [_sliceGlobals] walks argv, plucks global tokens (and their
///          values for option-style flags) into `globalArgs`; everything
///          else goes to `rest` preserving relative order.
/// Pass B — A small dedicated [ArgParser] parses `globalArgs`. Unknown
///          flags inside `globalArgs` are now impossible by construction,
///          so this `parser.parse` call NEVER throws on unknown-flag.
///          It DOES throw on bad `--output` value (e.g. `--output=foo`)
///          or missing `--bff` value — both intentional, propagate as
///          [_GlobalsUsage] → exit 64.
///
/// SEC: replaces the previous `try { ... } on FormatException { return defaults }`
/// — a CATASTROPHIC silent-fallback path (audit B1, 2026-05-04) where any
/// subcommand-specific flag (e.g. `--search=foo`) made `_parseGlobals`
/// throw and discard the user-supplied `--bff` / `--output`. The 2-pass
/// design makes that fallback unreachable: an `ArgParserException` here
/// can only originate from a malformed VALUE for one of the three
/// recognised globals, never from an unknown-flag clash.
///
/// SEC (defense-in-depth): every BFF URL — explicit flag OR build-time
/// default — passes through [validateBffUrl]. Even a malicious
/// `--dart-define=ACDG_BFF_URL=http://evil.tld` build cannot escape.
_GlobalsOrError _parseGlobals(List<String> args) {
  final (globalArgs, _) = _sliceGlobals(args);
  final parser = ArgParser()
    ..addOption('bff') // no defaultsTo — null means "user did not pass it"
    ..addOption('output', allowed: _outputFormats)
    ..addFlag('quiet', abbr: 'q', negatable: false);
  final ArgResults results;
  try {
    results = parser.parse(globalArgs);
    // ignore: unused_catch_stack
  } on FormatException catch (e, st) {
    return _GlobalsOrError.usage(e.message);
  }
  final outputRaw = results['output'] as String?;
  final bffRaw = results['bff'] as String?;
  // SEC: validate the effective BFF URL (explicit flag or default).
  final bffCandidate = bffRaw ?? _defaultBffUrl;
  final allowResult = validateBffUrl(bffCandidate);
  return switch (allowResult) {
    Success(:final value) => _GlobalsOrError.ok(
      _GlobalFlags(
        output: outputRaw == 'auto' ? null : outputRaw,
        bffUrl: value.toString(),
      ),
    ),
    Failure(:final error) => _GlobalsOrError.bff(error as BffAllowlistError),
  };
}

/// argv slicer — plucks global tokens out of [args] without invoking any
/// parser. Recognises three POSIX/GNU flag forms:
///   * long with `=` value:    `--bff=URL` / `--output=json`
///   * long with space value:  `--bff URL` / `--output json`
///   * boolean (no value):     `--quiet` / `-q`
/// `--` terminates flag scanning (everything after is positional / pass-through
/// per POSIX), so `--bff=...` after a `--` is NOT plucked.
(List<String> globals, List<String> rest) _sliceGlobals(List<String> args) {
  final globals = <String>[];
  final rest = <String>[];
  var passthrough = false;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (passthrough) {
      rest.add(a);
      continue;
    }
    if (a == '--') {
      passthrough = true;
      rest.add(a);
      continue;
    }
    final isLong = a.startsWith('--');
    final isShort = !isLong && a.startsWith('-') && a.length > 1;
    String? name;
    var hasInlineValue = false;
    if (isLong) {
      final eq = a.indexOf('=');
      name = eq < 0 ? a.substring(2) : a.substring(2, eq);
      hasInlineValue = eq >= 0;
    } else if (isShort) {
      // Single-letter only — no bundling for globals (`-qv` is rejected
      // upstream by the assembled CommandRunner, never by the slicer).
      name = a.substring(1);
    }
    final isGlobalLong = isLong && _globalLongFlags.contains(name);
    final isGlobalShort = isShort && _globalShortFlags.contains(name);
    if (isGlobalLong || isGlobalShort) {
      globals.add(a);
      // For option-style globals (`--bff`, `--output`), consume the next
      // argv slot when the value isn't inlined with `=`.
      final isOption = isLong && _globalLongOptions.contains(name);
      if (isOption && !hasInlineValue && i + 1 < args.length) {
        globals.add(args[++i]);
      }
    } else {
      rest.add(a);
    }
  }
  return (globals, rest);
}

/// True when [sink] is a real `Stdout` attached to a TTY. Test harnesses
/// pass a `StringBuffer`, which is treated as a pipe (false) so `--output`
/// auto-mode picks JSON.
bool _stdoutHasTerminal(StringSink sink) {
  return sink is Stdout && sink.hasTerminal;
}

/// Inert [CredentialStore] used when [CredentialStoreFactory.createSync]
/// returns `Failure` (unsupported platform, missing env var). Read returns
/// `null` so the next BFF call surfaces `AuthRequiredError`; write throws
/// `StateError` so `acdg auth login` fails fast rather than silently
/// dropping the freshly minted session into the void.
final class _UnavailableCredentialStore implements CredentialStore {
  const _UnavailableCredentialStore();

  @override
  Future<OidcSession?> read() async => null;

  @override
  Future<void> write(OidcSession session) async {
    // SEC: fail-loud. Silently swallowing a write would lose the user's
    // session without warning.
    throw StateError(
      'Credential storage unavailable on this platform. '
      'Re-install on macOS, Linux (with libsecret-tools), or Windows.',
    );
  }

  @override
  Future<void> clear() async {
    // No-op — there is nothing to clear on a missing store.
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
  required http.Client httpClient,
  required CredentialStore credentialStore,
  required Future<Result<OidcDiscovery>> Function() loadDiscovery,
  required StringSink stdout,
  required StringSink stderr,
  DateTime Function()? clock,
}) {
  return AuthCommand(
    login: AuthLoginCommand(
      discoveryLoader: loadDiscovery,
      pkceFactory: PkcePair.generate,
      listenerFactory: ({required String expectedState}) =>
          LoopbackListener(expectedState: expectedState),
      tokenClientFactory: (discovery) =>
          TokenClient(discovery: discovery, httpClient: httpClient),
      credentialStore: credentialStore,
      browserOpener: _openBrowser,
      stateNonceFactory: _generateStateNonce,
      stdout: stdout,
      stderr: stderr,
    ),
    status: AuthStatusCommand(
      credentialStore: credentialStore,
      now: clock,
      stdout: stdout,
      stderr: stderr,
    ),
    logout: AuthLogoutCommand(
      credentialStore: credentialStore,
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
      credentialStore: credentialStore,
      discoveryLoader: loadDiscovery,
      tokenClientFactory: (discovery) =>
          TokenClient(discovery: discovery, httpClient: httpClient),
      stdout: stdout,
      stderr: stderr,
    ),
  );
}

/// Builds the production [BffClient] using the shared [credentialStore].
///
/// The [TokenClient] / [OidcDiscovery] wiring is deferred until the first
/// 401: [BffClient] receives a `tokenClient` only after discovery resolves,
/// so the shared `loadDiscovery` is invoked on demand inside the closure.
/// In the C03 wave, the simpler shape (no refresh-on-401 wiring) is fine —
/// the auth subcommands handle refresh explicitly.
///
/// When [adapter] is supplied (golden tests), a fresh [Dio] is wired with
/// that adapter and passed to [BffClient]. Production callers leave
/// [adapter] null and get the default Dio transport.
BffClient _buildBffClient({
  required String baseUrl,
  required CredentialStore credentialStore,
  HttpClientAdapter? adapter,
}) {
  Dio? dio;
  if (adapter != null) {
    dio = Dio()..httpClientAdapter = adapter;
  }
  return BffClient(
    baseUrl: baseUrl,
    credentialStore: credentialStore,
    dio: dio,
  );
}

/// Builds the production [PatientCommand] with all eight subcommands wired
/// against the shared [bffClient]. [formatter] is resolved per-invocation
/// from `--output` by [CliRunner.run].
PatientCommand _buildPatientCommand({
  required BffClient bffClient,
  required OutputFormatter formatter,
  required StringSink stdout,
  required StringSink stderr,
}) {
  return PatientCommand(
    list: PatientListCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    get: PatientGetCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    audit: PatientAuditCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    register: PatientRegisterCommand(
      bffClient: bffClient,
      formatter: formatter,
      fileReader: (path) => File(path).readAsString(),
      stdout: stdout,
      stderr: stderr,
    ),
    admit: PatientAdmitCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    discharge: PatientDischargeCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    readmit: PatientReadmitCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    withdraw: PatientWithdrawCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
  );
}

/// Builds the production [FamilyCommand] with all four subcommands wired
/// against the shared [bffClient]. [formatter] is resolved per-invocation
/// from `--output` by [CliRunner.run].
FamilyCommand _buildFamilyCommand({
  required BffClient bffClient,
  required OutputFormatter formatter,
  required StringSink stdout,
  required StringSink stderr,
}) {
  return FamilyCommand(
    add: FamilyAddCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    remove: FamilyRemoveCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    assignCaregiver: FamilyAssignCaregiverCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    updateIdentity: FamilyUpdateIdentityCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
  );
}

/// Builds the production [AssessmentCommand] with all seven ficha
/// subcommands wired against the shared [bffClient]. [formatter] is
/// resolved per-invocation from `--output` by [CliRunner.run]. Each ficha
/// shares the same `fileReader` closure so `--from-yaml` paths are read
/// uniformly.
AssessmentCommand _buildAssessmentCommand({
  required BffClient bffClient,
  required OutputFormatter formatter,
  required StringSink stdout,
  required StringSink stderr,
}) {
  Future<String> readFile(String path) => File(path).readAsString();
  return AssessmentCommand(
    housing: AssessmentHousingCommand(
      bffClient: bffClient,
      formatter: formatter,
      fileReader: readFile,
      stdout: stdout,
      stderr: stderr,
    ),
    socioeconomic: AssessmentSocioeconomicCommand(
      bffClient: bffClient,
      formatter: formatter,
      fileReader: readFile,
      stdout: stdout,
      stderr: stderr,
    ),
    workIncome: AssessmentWorkIncomeCommand(
      bffClient: bffClient,
      formatter: formatter,
      fileReader: readFile,
      stdout: stdout,
      stderr: stderr,
    ),
    education: AssessmentEducationCommand(
      bffClient: bffClient,
      formatter: formatter,
      fileReader: readFile,
      stdout: stdout,
      stderr: stderr,
    ),
    health: AssessmentHealthCommand(
      bffClient: bffClient,
      formatter: formatter,
      fileReader: readFile,
      stdout: stdout,
      stderr: stderr,
    ),
    communitySupport: AssessmentCommunitySupportCommand(
      bffClient: bffClient,
      formatter: formatter,
      fileReader: readFile,
      stdout: stdout,
      stderr: stderr,
    ),
    socialHealthSummary: AssessmentSocialHealthSummaryCommand(
      bffClient: bffClient,
      formatter: formatter,
      fileReader: readFile,
      stdout: stdout,
      stderr: stderr,
    ),
  );
}

/// Builds the production [CareCommand] with both subcommands wired against
/// the shared [bffClient]. [formatter] is resolved per-invocation from
/// `--output` by [CliRunner.run].
CareCommand _buildCareCommand({
  required BffClient bffClient,
  required OutputFormatter formatter,
  required StringSink stdout,
  required StringSink stderr,
}) {
  return CareCommand(
    appointment: CareAppointmentCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    intake: CareIntakeCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
  );
}

/// Builds the production [ProtectionCommand] with all three subcommands
/// wired against the shared [bffClient]. [formatter] is resolved per-
/// invocation from `--output` by [CliRunner.run]. The `placement-history`
/// verb is YAML-only and shares the same `fileReader` closure used by C03
/// patient register + C05 assessments.
ProtectionCommand _buildProtectionCommand({
  required BffClient bffClient,
  required OutputFormatter formatter,
  required StringSink stdout,
  required StringSink stderr,
}) {
  return ProtectionCommand(
    violation: ProtectionViolationCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    referral: ProtectionReferralCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    placementHistory: ProtectionPlacementHistoryCommand(
      bffClient: bffClient,
      formatter: formatter,
      fileReader: (path) => File(path).readAsString(),
      stdout: stdout,
      stderr: stderr,
    ),
  );
}

/// Builds the production [LookupCommand] with all five admin/read leaves and
/// the four governance leaves (under the `request` sub-parent) wired against
/// the shared [bffClient]. [formatter] is resolved per-invocation from
/// `--output` by [CliRunner.run].
LookupCommand _buildLookupCommand({
  required BffClient bffClient,
  required OutputFormatter formatter,
  required StringSink stdout,
  required StringSink stderr,
}) {
  return LookupCommand(
    get: LookupGetCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    batch: LookupBatchCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    create: LookupCreateCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    update: LookupUpdateCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    toggle: LookupToggleCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    request: LookupRequestCommand(
      list: LookupRequestListCommand(
        bffClient: bffClient,
        formatter: formatter,
        stdout: stdout,
        stderr: stderr,
      ),
      create: LookupRequestCreateCommand(
        bffClient: bffClient,
        formatter: formatter,
        stdout: stdout,
        stderr: stderr,
      ),
      approve: LookupRequestApproveCommand(
        bffClient: bffClient,
        formatter: formatter,
        stdout: stdout,
        stderr: stderr,
      ),
      reject: LookupRequestRejectCommand(
        bffClient: bffClient,
        formatter: formatter,
        stdout: stdout,
        stderr: stderr,
      ),
    ),
  );
}

/// Builds the production [TeamCommand] with all six top-level leaves and the
/// three role-assignment leaves (under the `role` sub-parent) wired against
/// the shared [bffClient]. [formatter] is resolved per-invocation from
/// `--output` by [CliRunner.run].
TeamCommand _buildTeamCommand({
  required BffClient bffClient,
  required OutputFormatter formatter,
  required StringSink stdout,
  required StringSink stderr,
}) {
  return TeamCommand(
    list: TeamListCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    register: TeamRegisterCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    get: TeamGetCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    deactivate: TeamDeactivateCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    reactivate: TeamReactivateCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    resetPassword: TeamResetPasswordCommand(
      bffClient: bffClient,
      formatter: formatter,
      stdout: stdout,
      stderr: stderr,
    ),
    role: TeamRoleCommand(
      assign: TeamRoleAssignCommand(
        bffClient: bffClient,
        formatter: formatter,
        stdout: stdout,
        stderr: stderr,
      ),
      deactivate: TeamRoleDeactivateCommand(
        bffClient: bffClient,
        formatter: formatter,
        stdout: stdout,
        stderr: stderr,
      ),
      reactivate: TeamRoleReactivateCommand(
        bffClient: bffClient,
        formatter: formatter,
        stdout: stdout,
        stderr: stderr,
      ),
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
