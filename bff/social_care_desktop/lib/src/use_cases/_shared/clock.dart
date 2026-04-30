/// Minimal injectable clock so use cases can compute staleness +
/// mutation `createdAt` without colliding with wall-clock drift in CI.
///
/// Production code wires `const Clock()`; tests substitute `FakeClock`
/// in `test/use_cases/_test_helpers.dart` to advance time
/// deterministically.
library;

class Clock {
  const Clock();

  DateTime now() => DateTime.now();
}
