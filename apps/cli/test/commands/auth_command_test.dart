/// W0.5 RED — `AuthCommand` stub contract.
///
/// W1 must create `apps/cli/lib/src/commands/auth_command.dart` with an
/// `AuthCommand` class that:
///   * extends `args.Command<int>`
///   * has `name == 'auth'`
///   * has a non-empty `description`
///   * accepts an injectable `StringSink stdout`
///   * `run()` returns 0 and prints `'Not implemented yet — pending C02'` to stdout
///
/// Real auth implementation lands in C02 (PKCE Loopback).
library;

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/auth_command.dart';

void main() {
  group('AuthCommand (stub — pending C02)', () {
    test('extends args.Command<int>', () {
      expect(AuthCommand(), isA<Command<int>>());
    });

    test('name is "auth"', () {
      expect(AuthCommand().name, equals('auth'));
    });

    test('description is non-empty', () {
      expect(AuthCommand().description, isNotEmpty);
    });

    test('run() returns 0 and prints stub message naming C02', () async {
      final out = StringBuffer();
      final cmd = AuthCommand(stdout: out);

      final exitCode = await cmd.run();

      expect(exitCode, equals(0));
      expect(out.toString(), contains('Not implemented yet'));
      expect(out.toString(), contains('C02'));
    });
  });
}
