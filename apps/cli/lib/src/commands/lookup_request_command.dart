/// `acdg lookup request` — governance sub-parent (C08).
///
/// **First sub-parent (parent of parents) in the CLI canon.** Owns the four
/// governance leaves:
///   `list`, `create`, `approve`, `reject`.
///
/// Reachable via `acdg lookup request <leaf>`. Note the SINGULAR `request`:
/// the ticket §Escopo wrote `requests list` (plural) but the other governance
/// verbs (`request create|approve|reject`) used the singular. Two separate
/// parents would mean a single-verb `requests` group — collapsed into one
/// sub-parent named `request` for consistency. See `lookup_command.dart` and
/// the C08 W0 REPORT §"Decisions".
///
/// Mirrors the top-level parents (`PatientCommand`, `FamilyCommand`,
/// `LookupCommand`, etc.): when constructed without collaborators (e.g. by
/// `args` introspection in tests), it falls back to schema-only placeholder
/// subcommands so `--help` still advertises the canonical four names.
library;

import 'package:args/command_runner.dart';

import 'lookup_request_approve_command.dart';
import 'lookup_request_create_command.dart';
import 'lookup_request_list_command.dart';
import 'lookup_request_reject_command.dart';

/// Parent for `acdg lookup request list|create|approve|reject`.
final class LookupRequestCommand extends Command<int> {
  LookupRequestCommand({
    LookupRequestListCommand? list,
    LookupRequestCreateCommand? create,
    LookupRequestApproveCommand? approve,
    LookupRequestRejectCommand? reject,
  }) {
    if (list != null) addSubcommand(list);
    if (create != null) addSubcommand(create);
    if (approve != null) addSubcommand(approve);
    if (reject != null) addSubcommand(reject);

    // Without wired collaborators (tests / `--help` introspection) register
    // schema-only placeholders so the four names appear under `subcommands`.
    if (subcommands.isEmpty) {
      addSubcommand(_PlaceholderCommand('list'));
      addSubcommand(_PlaceholderCommand('create'));
      addSubcommand(_PlaceholderCommand('approve'));
      addSubcommand(_PlaceholderCommand('reject'));
    }
  }

  @override
  String get name => 'request';

  @override
  String get description =>
      'Lookup governance requests (list, create, approve, reject).';

  @override
  Future<int> run() async {
    // `acdg lookup request` with no leaf → EX_USAGE.
    return 64;
  }
}

/// Schema-only placeholder used when [LookupRequestCommand] is constructed
/// with no collaborators. Real subcommands are injected by `cli_runner.dart`.
final class _PlaceholderCommand extends Command<int> {
  _PlaceholderCommand(this.name);

  @override
  final String name;

  @override
  String get description => 'lookup request $name';

  @override
  Future<int> run() async => 64;
}
