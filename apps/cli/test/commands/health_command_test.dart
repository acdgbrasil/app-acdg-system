/// W0.5 RED — `HealthCommand` stub contract.
///
/// Health is a service health probe (not a domain command in the C03–C09
/// onda-3/4 list). The C01 stub message therefore does NOT name a follow-up
/// ticket — only "Not implemented yet". Real impl lands later (likely
/// folded into C03 or polish ticket C10/C11; W1/W2 may pin a ticket if
/// they choose, in which case the stub message can include it).
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/health_command.dart';

void main() {
  group('HealthCommand (stub — pending implementation)', () {
    test('extends args.Command<int>', () {
      expect(HealthCommand(), isA<Command<int>>());
    });

    test('name is "health"', () {
      expect(HealthCommand().name, equals('health'));
    });

    test('description is non-empty', () {
      expect(HealthCommand().description, isNotEmpty);
    });

    test('run() returns 0 and prints stub message', () async {
      final out = StringBuffer();
      final cmd = HealthCommand(stdout: out);

      final exitCode = await cmd.run();

      expect(exitCode, equals(0));
      expect(out.toString(), contains('Not implemented yet'));
    });
  });
}
