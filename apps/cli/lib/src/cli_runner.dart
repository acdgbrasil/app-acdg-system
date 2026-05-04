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
    _credentialStore =
        credentialStore ??
        FileCredentialStore(
          path: FileCredentialStore.defaultPath(env: Platform.environment),
        );
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
    final globals = _parseGlobals(args);
    final OutputFormatter formatter;
    try {
      formatter = resolveFormatter(
        explicitFormat: globals.output,
        isTerminal: _stdoutHasTerminal(_stdout),
      );
    } on InvalidArgError catch (e) {
      _stderr.writeln(e.message);
      return 64;
    }
    final assembled = _assemble(formatter: formatter, baseUrl: globals.bffUrl);
    _runner = assembled;
    try {
      final exitCode = await assembled.run(args);
      return exitCode ?? 0;
    } on UsageException catch (e) {
      _stderr
        ..writeln(e.message)
        ..writeln()
        ..writeln(e.usage);
      return 64; // EX_USAGE per sysexits(3).
    }
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

/// Best-effort global-flag side parse. Matches the global flag set wired
/// inside [_assemble]; failures (unknown sub-command, missing argument)
/// fall through to defaults — the assembled runner will surface the real
/// usage error.
_GlobalFlags _parseGlobals(List<String> args) {
  final parser = ArgParser(allowTrailingOptions: true)
    ..addOption('bff', defaultsTo: _defaultBffUrl)
    ..addOption('output', allowed: _outputFormats, defaultsTo: 'auto')
    ..addFlag('quiet', defaultsTo: false, negatable: false);
  try {
    final results = parser.parse(args);
    final outputRaw = results['output'] as String?;
    return _GlobalFlags(
      output: outputRaw == 'auto' ? null : outputRaw,
      bffUrl: results['bff'] as String? ?? _defaultBffUrl,
    );
  } on FormatException {
    // `ArgParserException` is a `FormatException` subclass — both invalid
    // `--output` values and unknown sub-commands surface here. Fall back
    // to defaults; the assembled runner will surface the real usage error.
    return const _GlobalFlags(output: null, bffUrl: _defaultBffUrl);
  }
}

/// True when [sink] is a real `Stdout` attached to a TTY. Test harnesses
/// pass a `StringBuffer`, which is treated as a pipe (false) so `--output`
/// auto-mode picks JSON.
bool _stdoutHasTerminal(StringSink sink) {
  return sink is Stdout && sink.hasTerminal;
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
