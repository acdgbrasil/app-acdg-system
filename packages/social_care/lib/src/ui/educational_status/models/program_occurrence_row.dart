/// Mutable form state for a program occurrence entry.
class ProgramOccurrenceRow {
  String? memberId;
  String date;
  String? effectId;
  bool isSuspensionRequested;

  ProgramOccurrenceRow({
    this.memberId,
    this.date = '',
    this.effectId,
    this.isSuspensionRequested = false,
  });
}
