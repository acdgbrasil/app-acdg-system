/// W0.5 RED — `LookupCommand` stub contract. Real impl lands in C08.
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/lookup_command.dart';

void main() {
  group('LookupCommand (stub — pending C08)', () {
    test('extends args.Command<int>', () {
      expect(LookupCommand(), isA<Command<int>>());
    });

    test('name is "lookup"', () {
      expect(LookupCommand().name, equals('lookup'));
    });

    test('description is non-empty', () {
      expect(LookupCommand().description, isNotEmpty);
    });

    test('run() returns 0 and prints stub message naming C08', () async {
      final out = StringBuffer();
      final cmd = LookupCommand(stdout: out);

      final exitCode = await cmd.run();

      expect(exitCode, equals(0));
      expect(out.toString(), contains('Not implemented yet'));
      expect(out.toString(), contains('C08'));
    });
  });
}
