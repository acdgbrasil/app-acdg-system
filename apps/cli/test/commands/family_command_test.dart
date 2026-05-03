/// W0.5 RED — `FamilyCommand` stub contract. Real impl lands in C04.
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/family_command.dart';

void main() {
  group('FamilyCommand (stub — pending C04)', () {
    test('extends args.Command<int>', () {
      expect(FamilyCommand(), isA<Command<int>>());
    });

    test('name is "family"', () {
      expect(FamilyCommand().name, equals('family'));
    });

    test('description is non-empty', () {
      expect(FamilyCommand().description, isNotEmpty);
    });

    test('run() returns 0 and prints stub message naming C04', () async {
      final out = StringBuffer();
      final cmd = FamilyCommand(stdout: out);

      final exitCode = await cmd.run();

      expect(exitCode, equals(0));
      expect(out.toString(), contains('Not implemented yet'));
      expect(out.toString(), contains('C04'));
    });
  });
}
