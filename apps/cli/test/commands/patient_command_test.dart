/// W0.5 RED — `PatientCommand` stub contract.
///
/// W1 must create `apps/cli/lib/src/commands/patient_command.dart`. Real
/// patient operations land in C03.
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/patient_command.dart';

void main() {
  group('PatientCommand (stub — pending C03)', () {
    test('extends args.Command<int>', () {
      expect(PatientCommand(), isA<Command<int>>());
    });

    test('name is "patient"', () {
      expect(PatientCommand().name, equals('patient'));
    });

    test('description is non-empty', () {
      expect(PatientCommand().description, isNotEmpty);
    });

    test('run() returns 0 and prints stub message naming C03', () async {
      final out = StringBuffer();
      final cmd = PatientCommand(stdout: out);

      final exitCode = await cmd.run();

      expect(exitCode, equals(0));
      expect(out.toString(), contains('Not implemented yet'));
      expect(out.toString(), contains('C03'));
    });
  });
}
