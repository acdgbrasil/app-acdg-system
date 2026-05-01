/// Minimal injectable clock interface so use cases can compute staleness +
/// mutation `createdAt` without colliding with wall-clock drift in CI.
///
/// Per H6 in `handbook/principles/DECISION_HEURISTICS.md`, [Clock] is an
/// `abstract interface class` — substituted ONLY via `implements`. This
/// prevents accidental fallback to real `DateTime.now()` via `super.now()`
/// in test fakes.
///
/// Production code wires `const SystemClock()`; tests substitute
/// `FakeClock implements Clock` to advance time deterministically.
library;

abstract interface class Clock {
  DateTime now();
}

/// Wall-clock implementation. The default for production wiring.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
