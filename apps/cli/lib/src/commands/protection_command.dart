/// `acdg protection` — violations, referrals, placement. Stub for C01; real impl C07.
library;

import 'package:args/command_runner.dart';

import '_stub_command.dart';

/// Protection verbs (referral, violation report, placement history). Stubbed for C01.
final class ProtectionCommand extends Command<int> {
  ProtectionCommand({StringSink? stdout}) : _stdout = stdout;

  final StringSink? _stdout;

  @override
  String get name => 'protection';

  @override
  String get description => 'Violations, referrals, placement';

  @override
  Future<int> run() => writeStub(out: _stdout, pendingTicket: 'C07');
}
