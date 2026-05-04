/// `acdg team list` — list team members (C09).
///
/// GETs `/team` and renders the `data` payload (a list of
/// `TeamMemberResponse` objects) via the injected [OutputFormatter].
///
/// **Query-tolerant intent.** All three filters are optional — first BFF
/// intent in the canon where ZERO query params is a valid call (lists every
/// team member). The CLI ONLY adds a key to `queryParameters` when the
/// matching flag was passed. We do NOT send `role=&active=&search=` when
/// the user passed nothing — the BFF intent
/// `list_team_intent.dart:65-69` treats empty strings as null but the CLI
/// shouldn't depend on that latitude. (W0 §4 — D4.)
///
/// **`--active` is a string flag.** BFF intent
/// `list_team_intent.dart:65-79` accepts ONLY the literal strings
/// `"true"` / `"false"`. The CLI forwards the raw flag value as-is — no
/// client-side validation, no `bool.parse`. A bad value (`--active=abc`)
/// is rejected by the BFF as `INVALID_LIST_TEAM_QUERY` 400. (W0 §4 — D5.)
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../formatters/output_formatter.dart';
import '../session/bff_client.dart';
import '_command_helpers.dart';

/// `acdg team list`.
final class TeamListCommand extends Command<int> {
  TeamListCommand({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  }) {
    argParser
      ..addOption('role', help: 'Filter by role code (optional)')
      ..addOption(
        'active',
        help: 'Filter by active flag: literal "true" or "false" (optional)',
      )
      ..addOption('search', help: 'Free-text search (optional)');
  }

  final BffClient bffClient;
  final OutputFormatter formatter;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'list';

  @override
  String get description =>
      'List team members (filters: --role, --active, --search; all optional).';

  @override
  String get invocation =>
      'acdg team list [--role=X] [--active=true|false] [--search=Y]';

  @override
  Future<int> run() async {
    final qp = <String, Object?>{};
    final role = argResults?['role'] as String?;
    final active = argResults?['active'] as String?;
    final search = argResults?['search'] as String?;
    if (role != null && role.isNotEmpty) qp['role'] = role;
    if (active != null && active.isNotEmpty) qp['active'] = active;
    if (search != null && search.isNotEmpty) qp['search'] = search;

    final result = await bffClient.get<Object?>(
      '/team',
      queryParameters: qp.isEmpty ? null : qp,
    );
    switch (result) {
      case Success(:final value):
        final map = value is Map<String, Object?> ? value : null;
        final data = map?['data'];
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
