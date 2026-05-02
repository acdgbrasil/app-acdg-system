/// Typed failures emitted by A18b-v2 use cases.
///
/// Carry semantic meaning beyond a string — `NotFoundFailure` is what
/// non-Register write use cases emit when the optimistic-locking version
/// can't be read because the cached aggregate is missing. Tests assert
/// `Failure.error is NotFoundFailure` to distinguish from outbox /
/// remote / cache failures.
library;

class NotFoundFailure {
  const NotFoundFailure(this.message);

  final String message;

  @override
  String toString() => 'NotFoundFailure: $message';
}
