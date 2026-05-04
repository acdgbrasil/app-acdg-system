/// W0 RED — `PatientCommand` parent contract under C03.
///
/// **Replaces the C01 stub contract.** C01 declared `PatientCommand` as a leaf
/// command that printed "Not implemented yet — pending C03". C03 makes it a
/// parent command holding 8 subcommands: `list`, `get`, `audit`, `register`,
/// `admit`, `discharge`, `readmit`, `withdraw` (ticket §Escopo).
///
/// W1 must update `apps/cli/lib/src/commands/patient_command.dart` so that:
///
/// ```dart
/// class PatientCommand extends Command<int> {
///   PatientCommand({
///     PatientListCommand? list,
///     PatientGetCommand? get,
///     PatientAuditCommand? audit,
///     PatientRegisterCommand? register,
///     PatientAdmitCommand? admit,
///     PatientDischargeCommand? discharge,
///     PatientReadmitCommand? readmit,
///     PatientWithdrawCommand? withdraw,
///   }) {
///     // wire injected subcommands; fall back to schema-only placeholders
///     // so `--help` still advertises the canonical 8 names when ctor is
///     // called with no collaborators (mirrors AuthCommand C02 contract).
///   }
///   @override String get name => 'patient';
///   @override String get description => '...non-empty...';
/// }
/// ```
///
/// Subcommand-level orchestration tests live in:
///   * `patient_list_command_test.dart`
///   * `patient_get_command_test.dart`
///   * `patient_audit_command_test.dart`
///   * `patient_register_command_test.dart`
///   * `patient_admit_command_test.dart`
///   * `patient_discharge_command_test.dart`
///   * `patient_readmit_command_test.dart`
///   * `patient_withdraw_command_test.dart`
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/patient_command.dart';

void main() {
  group('PatientCommand parent (C03)', () {
    test('extends args.Command<int>', () {
      expect(PatientCommand(), isA<Command<int>>());
    });

    test('name is "patient"', () {
      expect(PatientCommand().name, equals('patient'));
    });

    test('description is non-empty', () {
      expect(PatientCommand().description, isNotEmpty);
    });

    test('registers the 8 subcommands required by the ticket: '
        'list/get/audit/register/admit/discharge/readmit/withdraw', () {
      final cmd = PatientCommand();
      final names = cmd.subcommands.keys.toSet();

      expect(names, contains('list'));
      expect(names, contains('get'));
      expect(names, contains('audit'));
      expect(names, contains('register'));
      expect(names, contains('admit'));
      expect(names, contains('discharge'));
      expect(names, contains('readmit'));
      expect(names, contains('withdraw'));
    });

    test(
      'parent without subcommand returns non-zero exit (EX_USAGE)',
      () async {
        // `acdg patient` with no verb should print usage and exit non-zero.
        // Mirrors AuthCommand's 64 exit code (EX_USAGE per sysexits(3)).
        final cmd = PatientCommand();

        final exitCode = await cmd.run();

        expect(exitCode, isNot(equals(0)));
      },
    );
  });
}
