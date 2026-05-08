/// `acdg team register` — register a new worker (C09).
///
/// POSTs `/team` with the [RegisterPersonWithLoginRequest] body shape:
///
/// ```json
/// {
///   "fullName": "<full-name>",
///   "birthDate": "<YYYY-MM-DD>",
///   "email": "<email>",
///   "cpf": "<cpf>",                       // optional
///   "initialPassword": "<initial-pw>"     // optional
/// }
/// ```
///
/// **Composite saga endpoint.** Internally the BFF runs PeopleContext.register
/// + Team.createWorker + Team.assignRole, but on the WIRE the only POST
/// body is the 3 required + 2 optional fields above. Initial role assignment
/// is a TWO-step UX from the CLI: `acdg team register` then
/// `acdg team role assign <new-id>` — there is no `--initial-role` sugar.
///
/// **DTO-as-canon (deviation from CLI flag spelling).** Ticket prose lists
/// `--first-name`/`--role` flags. The DTO has neither — it is
/// `{fullName, birthDate, email, cpf?, initialPassword?}`. CLI flags use
/// kebab-case for the human surface and translate to DTO camelCase on the
/// wire. (Mirrors C03 W2 M1 / C08 D2.)
///
/// **5xx UX (saga edge case).** When the BFF saga fails after the
/// PeopleContext.register call (e.g. Zitadel quota exceeded or a downstream
/// 5xx mid-saga), the CLI does NOT enforce rollback — that is the BFF's
/// responsibility (cf. `register_worker_use_case.dart`). What it DOES do is
/// surface a clear recovery hint on stderr so the operator can investigate
/// via `acdg team get <id>` if a partial record was created.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../errors/cli_error.dart';
import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg team register`.
final class TeamRegisterCommand extends Command<int> {
  TeamRegisterCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser
      // 3 required fields per RegisterPersonWithLoginRequest DTO.
      ..addOption('full-name', help: 'Full name (required, DTO `fullName`)')
      ..addOption(
        'birth-date',
        help: 'Birth date YYYY-MM-DD (required, DTO `birthDate`)',
      )
      ..addOption('email', help: 'Email (required, DTO `email`)')
      // 2 optional fields per the DTO.
      ..addOption('cpf', help: 'CPF (optional)')
      ..addOption(
        'initial-password',
        help: 'Initial password (optional, DTO `initialPassword`)',
      );
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'register';

  @override
  String get description =>
      'Register a new worker (composite saga: people + team + initial role).';

  @override
  String get invocation =>
      'acdg team register --full-name=... --birth-date=YYYY-MM-DD --email=... '
      '[--cpf=...] [--initial-password=...]';

  @override
  Future<int> run() async {
    final fullName = argResults?['full-name'] as String?;
    if (fullName == null || fullName.isEmpty) {
      usageException('Missing required option: --full-name');
    }
    final birthDate = argResults?['birth-date'] as String?;
    if (birthDate == null || birthDate.isEmpty) {
      usageException('Missing required option: --birth-date');
    }
    if (!_isValidIso8601Date(birthDate)) {
      usageException(
        '--birth-date must be a valid ISO8601 date (e.g. 1985-04-12); '
        'got: "$birthDate"',
      );
    }
    final email = argResults?['email'] as String?;
    if (email == null || email.isEmpty) {
      usageException('Missing required option: --email');
    }

    final body = dropNulls(<String, Object?>{
      'fullName': fullName,
      'birthDate': birthDate,
      'email': email,
      'cpf': argResults?['cpf'] as String?,
      'initialPassword': argResults?['initial-password'] as String?,
    });

    final result = await bffClient.post<String?>(
      '/team',
      body: body,
      decode: decodeStandardIdResponse,
    );
    switch (result) {
      case Success(:final value):
        if (value != null && value.isNotEmpty) {
          _writeOut('Registered worker $value');
        } else {
          _writeOut('Worker registered');
        }
        return 0;
      case Failure(:final error):
        final e = error as CliError;
        _writeErr(e.stderrMessage);
        if (error is ServerError && error.statusCode >= 500) {
          _writeErr(
            "Worker registration failed (saga). The person record may have "
            "been partially created; check via 'acdg team get <id>' or "
            'contact admin.',
          );
        }
        return e.exitCode;
    }
  }

  bool _isValidIso8601Date(String input) {
    // Adapter boundary — DateTime.parse throws FormatException on bad input.
    try {
      DateTime.parse(input);
      return true;
    } on FormatException {
      return false;
    }
  }

  void _writeOut(String line) {
    final out = stdout;
    if (out != null) out.writeln(line);
  }

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}
