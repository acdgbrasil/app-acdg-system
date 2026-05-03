/// Internal scaffold helper — every C01 sub-command is a stub printing
/// "Not implemented yet — pending CXX". Real behaviour lands in C02–C09.
///
/// Composition (not inheritance) over [Command]: each concrete command
/// extends `args.Command<int>` directly and delegates the body to
/// [writeStub], so [Command]'s reflective machinery (subcommands, argParser)
/// stays intact.
library;

/// Writes the canonical scaffold message and returns exit code 0.
///
/// * [out] — `null` falls back to `print` so a CLI invocation without an
///   injected sink still surfaces something on stdout.
/// * [pendingTicket] — `null` for HealthCommand (no follow-up ticket); a
///   string like `'C03'` for the rest.
Future<int> writeStub({
  required StringSink? out,
  required String? pendingTicket,
}) async {
  final suffix = pendingTicket != null ? ' — pending $pendingTicket' : '';
  final message = 'Not implemented yet$suffix\n';
  if (out != null) {
    out.write(message);
  } else {
    // Production stdout fallback — only hit when a command runs outside the
    // injected-sink path (currently never; reserved for future direct CLI use).
    // ignore: avoid_print
    print(message.trimRight());
  }
  return 0;
}
