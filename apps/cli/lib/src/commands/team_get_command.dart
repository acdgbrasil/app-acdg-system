/// `acdg team get <member-id>` — fetch a team member detail (C09).
///
/// GETs `/team/<id>` and renders the `data` payload (a
/// `TeamMemberDetailResponse` object) via the injected [OutputFormatter].
///
/// `<member-id>` is a literal pass-through — UUID v4 validation is enforced
/// server-side per `GetTeamMemberIntent.parseFromPath`. Missing positional →
/// usage error 64 (no BFF round trip).
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg team get`.
final class TeamGetCommand extends Command<int> {
  TeamGetCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  });

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'get';

  @override
  String get description => 'Fetch a team member by id (full detail).';

  @override
  String get invocation => 'acdg team get <member-id>';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? const <String>[];
    if (rest.isEmpty) {
      usageException('Missing required positional argument: <member-id>');
    }
    final memberId = rest.first;

    final result = await bffClient.get<Object?>('/team/$memberId');
    switch (result) {
      case Success(:final value):
        final data = value is Map<String, Object?> ? value['data'] : value;
        _writeOut(formatter.format(data));
        return 0;
      case Failure(:final error):
        _writeErr(stderrMessageFor(error));
        return exitCodeFor(error);
    }
  }

  void _writeOut(String text) {
    final out = stdout;
    if (out != null) out.write(text);
  }

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}
