/// `acdg lookup` — lookup tables and approval requests parent command (C08).
///
/// Holds the five Contract A admin/read verbs plus a sub-parent for the four
/// governance verbs:
///   `get`, `batch`, `create`, `update`, `toggle`, `request` (sub-parent).
///
/// **Sub-parent decision (deviation from ticket prose).** The ticket §Escopo
/// listed `lookup requests list` (PLURAL `requests`) for the listing verb but
/// `lookup request {create|approve|reject}` (SINGULAR) for the others. Two
/// separate parents would mean a single-verb `requests` group, confusing for
/// users. We collapse into a single sub-parent named `request` (singular)
/// owning the four leaves `list|create|approve|reject`. See
/// `lookup_request_command.dart` and the C08 W0 REPORT §"Decisions".
///
/// Mirrors `PatientCommand` (C03) / `FamilyCommand` (C04) /
/// `AssessmentCommand` (C05) / `CareCommand` (C06) / `ProtectionCommand`
/// (C07): when constructed without collaborators (e.g. by `args` introspection
/// in tests), it falls back to schema-only placeholder subcommands so `--help`
/// still advertises the canonical six entries.
library;

import 'package:args/command_runner.dart';

import 'lookup_batch_command.dart';
import 'lookup_create_command.dart';
import 'lookup_get_command.dart';
import 'lookup_request_command.dart';
import 'lookup_toggle_command.dart';
import 'lookup_update_command.dart';

/// Parent for `acdg lookup get|batch|create|update|toggle|request`.
final class LookupCommand extends Command<int> {
  LookupCommand({
    LookupGetCommand? get,
    LookupBatchCommand? batch,
    LookupCreateCommand? create,
    LookupUpdateCommand? update,
    LookupToggleCommand? toggle,
    LookupRequestCommand? request,
  }) {
    if (get != null) addSubcommand(get);
    if (batch != null) addSubcommand(batch);
    if (create != null) addSubcommand(create);
    if (update != null) addSubcommand(update);
    if (toggle != null) addSubcommand(toggle);
    if (request != null) addSubcommand(request);

    // Without wired collaborators (tests / `--help` introspection) register
    // schema-only placeholders so the six canonical names appear under
    // `subcommands`. The `request` placeholder is itself a parent so the
    // contract test for "request is itself a parent command" passes when no
    // injected sub-parent is provided.
    if (subcommands.isEmpty) {
      addSubcommand(_PlaceholderLeafCommand('get'));
      addSubcommand(_PlaceholderLeafCommand('batch'));
      addSubcommand(_PlaceholderLeafCommand('create'));
      addSubcommand(_PlaceholderLeafCommand('update'));
      addSubcommand(_PlaceholderLeafCommand('toggle'));
      addSubcommand(LookupRequestCommand());
    }
  }

  @override
  String get name => 'lookup';

  @override
  String get description =>
      'Lookup tables and approval requests '
      '(get, batch, create, update, toggle, request).';

  @override
  Future<int> run() async {
    // `acdg lookup` with no subcommand → EX_USAGE.
    // Avoid `printUsage()` here: it reaches `runner.usage` which is null
    // when the parent is invoked directly from a test (without a runner
    // attached). The CommandRunner path renders the usage banner before
    // calling `run`, so production invocations still see helpful output.
    return 64;
  }
}

/// Schema-only leaf placeholder used when [LookupCommand] is constructed with
/// no collaborators. Real subcommands are injected by `cli_runner.dart`.
final class _PlaceholderLeafCommand extends Command<int> {
  _PlaceholderLeafCommand(this.name);

  @override
  final String name;

  @override
  String get description => 'lookup $name';

  @override
  Future<int> run() async => 64;
}
