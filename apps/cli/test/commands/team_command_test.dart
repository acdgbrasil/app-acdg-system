/// W0.5 RED — `TeamCommand` stub contract. Real impl lands in C09.
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/team_command.dart';

void main() {
  group('TeamCommand (stub — pending C09)', () {
    test('extends args.Command<int>', () {
      expect(TeamCommand(), isA<Command<int>>());
    });

    test('name is "team"', () {
      expect(TeamCommand().name, equals('team'));
    });

    test('description is non-empty', () {
      expect(TeamCommand().description, isNotEmpty);
    });

    test('run() returns 0 and prints stub message naming C09', () async {
      final out = StringBuffer();
      final cmd = TeamCommand(stdout: out);

      final exitCode = await cmd.run();

      expect(exitCode, equals(0));
      expect(out.toString(), contains('Not implemented yet'));
      expect(out.toString(), contains('C09'));
    });
  });
}
