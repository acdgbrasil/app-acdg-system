/// W0.5 RED — `AssessmentCommand` stub contract. Real impl lands in C05.
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/assessment_command.dart';

void main() {
  group('AssessmentCommand (stub — pending C05)', () {
    test('extends args.Command<int>', () {
      expect(AssessmentCommand(), isA<Command<int>>());
    });

    test('name is "assessment"', () {
      expect(AssessmentCommand().name, equals('assessment'));
    });

    test('description is non-empty', () {
      expect(AssessmentCommand().description, isNotEmpty);
    });

    test('run() returns 0 and prints stub message naming C05', () async {
      final out = StringBuffer();
      final cmd = AssessmentCommand(stdout: out);

      final exitCode = await cmd.run();

      expect(exitCode, equals(0));
      expect(out.toString(), contains('Not implemented yet'));
      expect(out.toString(), contains('C05'));
    });
  });
}
