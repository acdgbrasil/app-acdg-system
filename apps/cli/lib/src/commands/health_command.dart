/// `acdg health` — service health probes. Stub for C01; impl folded into
/// later ticket (no dedicated CXX assigned at scaffold time).
library;

import 'package:args/command_runner.dart';

import '_stub_command.dart';

/// Health probe verbs (BFF, downstream services). Stubbed for C01.
final class HealthCommand extends Command<int> {
  HealthCommand({StringSink? stdout}) : _stdout = stdout;

  final StringSink? _stdout;

  @override
  String get name => 'health';

  @override
  String get description => 'Service health probes';

  @override
  Future<int> run() => writeStub(out: _stdout, pendingTicket: null);
}
