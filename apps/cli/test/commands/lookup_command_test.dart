/// W0 RED — `LookupCommand` parent contract under C08.
///
/// **Replaces the C01 stub contract.** C01 declared `LookupCommand` as a leaf
/// command that printed "Not implemented yet — pending C08". C08 makes it a
/// parent command holding 6 entries: 5 admin/read leaf verbs + 1 sub-parent
/// (`request`) that itself owns 4 governance leaf verbs.
///
/// The 9 underlying endpoints (cf. ticket §Escopo) collapse onto this shape:
///
/// ```
/// acdg lookup get <table>             # leaf
/// acdg lookup batch <a,b,c>           # leaf
/// acdg lookup create <table>          # leaf
/// acdg lookup update <table> <id>     # leaf
/// acdg lookup toggle <table> <id>     # leaf
/// acdg lookup request list            # via sub-parent
/// acdg lookup request create <table>  # via sub-parent
/// acdg lookup request approve <id>    # via sub-parent
/// acdg lookup request reject <id>     # via sub-parent
/// ```
///
/// **Naming decision (deviation from ticket prose).** Ticket §Escopo writes
/// `lookup requests list` (PLURAL `requests`) for the list verb but
/// `lookup request {create|approve|reject}` (SINGULAR `request`) for the
/// other governance verbs. Two separate parents would mean a single-verb
/// `requests` group — confusing and inconsistent with the user's mental
/// model. We collapse to a SINGLE sub-parent named `request` with 4 leaves:
/// `list`, `create`, `approve`, `reject`. So the command is
/// `acdg lookup request list` (singular). See REPORT.md §"Decisions".
///
/// W1 must update `apps/cli/lib/src/commands/lookup_command.dart` so that:
///
/// ```dart
/// class LookupCommand extends Command<int> {
///   LookupCommand({
///     LookupGetCommand? get,
///     LookupBatchCommand? batch,
///     LookupCreateCommand? create,
///     LookupUpdateCommand? update,
///     LookupToggleCommand? toggle,
///     LookupRequestCommand? request,  // sub-parent
///   }) {
///     // wire injected sub-commands; fall back to schema-only placeholders
///     // so `--help` still advertises all 6 names when ctor is called with
///     // no collaborators (mirrors PatientCommand C03 + FamilyCommand C04).
///   }
///   @override String get name => 'lookup';
///   @override String get description => '...non-empty...';
/// }
/// ```
///
/// Subcommand-level orchestration tests live in:
///   * `lookup_get_command_test.dart`
///   * `lookup_batch_command_test.dart`
///   * `lookup_create_command_test.dart`
///   * `lookup_update_command_test.dart`
///   * `lookup_toggle_command_test.dart`
///   * `lookup_request_command_test.dart` (sub-parent)
///   * `lookup_request_list_command_test.dart`
///   * `lookup_request_create_command_test.dart`
///   * `lookup_request_approve_command_test.dart`
///   * `lookup_request_reject_command_test.dart`
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/lookup_command.dart';

void main() {
  group('LookupCommand parent (C08)', () {
    test('extends args.Command<int>', () {
      expect(LookupCommand(), isA<Command<int>>());
    });

    test('name is "lookup"', () {
      expect(LookupCommand().name, equals('lookup'));
    });

    test('description is non-empty', () {
      expect(LookupCommand().description, isNotEmpty);
    });

    test('registers the 6 entries required by the ticket: '
        'get / batch / create / update / toggle / request (sub-parent)', () {
      final cmd = LookupCommand();
      final names = cmd.subcommands.keys.toSet();

      expect(names, contains('get'));
      expect(names, contains('batch'));
      expect(names, contains('create'));
      expect(names, contains('update'));
      expect(names, contains('toggle'));
      expect(names, contains('request'));
    });

    test('the "request" entry is itself a parent command (sub-parent)', () {
      // Sub-parent shape: `lookup request list|create|approve|reject` →
      // `request` owns 4 leaves. We assert non-emptiness here; the exact
      // 4-leaf set is pinned in `lookup_request_command_test.dart`.
      final cmd = LookupCommand();
      final request = cmd.subcommands['request'];

      expect(request, isNotNull);
      expect(
        request!.subcommands,
        isNotEmpty,
        reason: '"request" must be a parent owning governance leaves',
      );
    });

    test(
      'parent without subcommand returns non-zero exit (EX_USAGE)',
      () async {
        // `acdg lookup` with no verb should print usage and exit non-zero.
        // Mirrors PatientCommand / FamilyCommand: 64 exit code (EX_USAGE per
        // sysexits(3)).
        final cmd = LookupCommand();

        final exitCode = await cmd.run();

        expect(exitCode, isNot(equals(0)));
      },
    );
  });
}
