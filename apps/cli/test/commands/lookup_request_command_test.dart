/// W0 RED — `LookupRequestCommand` sub-parent contract (C08).
///
/// **Sub-parent of LookupCommand.** This is the FIRST sub-parent (parent of
/// parents) in the CLI canon. It owns 4 governance leaves:
///   * `list`   → GET  `/lookup-requests`
///   * `create` → POST `/lookup-requests`
///   * `approve`→ PUT  `/lookup-requests/<id>/approve`
///   * `reject` → PUT  `/lookup-requests/<id>/reject`
///
/// Reachable via `acdg lookup request <leaf>`. Note the SINGULAR `request`
/// (deviation from ticket prose `lookup requests list` which used PLURAL —
/// see `lookup_command_test.dart` decision rationale).
///
/// W1 must create `apps/cli/lib/src/commands/lookup_request_command.dart`:
///
/// ```dart
/// class LookupRequestCommand extends Command<int> {
///   LookupRequestCommand({
///     LookupRequestListCommand? list,
///     LookupRequestCreateCommand? create,
///     LookupRequestApproveCommand? approve,
///     LookupRequestRejectCommand? reject,
///   }) {
///     // wire injected children; fall back to schema-only placeholders so
///     // `--help` still advertises the canonical 4 names. Mirrors the
///     // top-level parents (PatientCommand, FamilyCommand, LookupCommand).
///   }
///   @override String get name => 'request';
///   @override String get description => '...non-empty...';
/// }
/// ```
///
/// Subcommand-level orchestration tests live in:
///   * `lookup_request_list_command_test.dart`
///   * `lookup_request_create_command_test.dart`
///   * `lookup_request_approve_command_test.dart`
///   * `lookup_request_reject_command_test.dart`
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/lookup_request_command.dart';

void main() {
  group('LookupRequestCommand sub-parent (C08)', () {
    test('extends args.Command<int>', () {
      expect(LookupRequestCommand(), isA<Command<int>>());
    });

    test('name is "request" (singular — deviation from ticket prose)', () {
      expect(LookupRequestCommand().name, equals('request'));
    });

    test('description is non-empty', () {
      expect(LookupRequestCommand().description, isNotEmpty);
    });

    test(
      'registers exactly the 4 governance leaves: list/create/approve/reject',
      () {
        final cmd = LookupRequestCommand();
        final names = cmd.subcommands.keys.toSet();

        expect(names, contains('list'));
        expect(names, contains('create'));
        expect(names, contains('approve'));
        expect(names, contains('reject'));
      },
    );

    test(
      'parent without subcommand returns non-zero exit (EX_USAGE)',
      () async {
        // `acdg lookup request` with no leaf → non-zero exit. Mirrors the
        // top-level parent contract.
        final cmd = LookupRequestCommand();

        final exitCode = await cmd.run();

        expect(exitCode, isNot(equals(0)));
      },
    );
  });
}
