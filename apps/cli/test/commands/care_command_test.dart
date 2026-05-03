/// W0.5 RED — `CareCommand` stub contract. Real impl lands in C06.
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/care_command.dart';

void main() {
  group('CareCommand (stub — pending C06)', () {
    test('extends args.Command<int>', () {
      expect(CareCommand(), isA<Command<int>>());
    });

    test('name is "care"', () {
      expect(CareCommand().name, equals('care'));
    });

    test('description is non-empty', () {
      expect(CareCommand().description, isNotEmpty);
    });

    test('run() returns 0 and prints stub message naming C06', () async {
      final out = StringBuffer();
      final cmd = CareCommand(stdout: out);

      final exitCode = await cmd.run();

      expect(exitCode, equals(0));
      expect(out.toString(), contains('Not implemented yet'));
      expect(out.toString(), contains('C06'));
    });
  });
}
