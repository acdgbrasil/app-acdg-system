/// W0.5 RED — `ProtectionCommand` stub contract. Real impl lands in C07.
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/protection_command.dart';

void main() {
  group('ProtectionCommand (stub — pending C07)', () {
    test('extends args.Command<int>', () {
      expect(ProtectionCommand(), isA<Command<int>>());
    });

    test('name is "protection"', () {
      expect(ProtectionCommand().name, equals('protection'));
    });

    test('description is non-empty', () {
      expect(ProtectionCommand().description, isNotEmpty);
    });

    test('run() returns 0 and prints stub message naming C07', () async {
      final out = StringBuffer();
      final cmd = ProtectionCommand(stdout: out);

      final exitCode = await cmd.run();

      expect(exitCode, equals(0));
      expect(out.toString(), contains('Not implemented yet'));
      expect(out.toString(), contains('C07'));
    });
  });
}
