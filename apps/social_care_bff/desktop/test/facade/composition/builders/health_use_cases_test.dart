/// RED-phase tests for `HealthUseCases` builder (D02 W0.5).
///
/// `HealthUseCases` groups the 2 Health probe use cases. They are pure
/// remote passthroughs — no cache, no outbox, no engine, no clock:
///   * `CheckHealthUseCase` — `remote: HealthContract` only
///   * `CheckReadyUseCase`  — `remote: HealthContract` only
///
/// So Health's `build()` is the slimmest of the 7 — it takes only
/// `remote:`. This is asymmetric with the other 6 builders and that
/// asymmetry is documented in the data class itself.
///
/// ── Surface under test ───────────────────────────────────────────────
///   * `class HealthUseCases`
///       - 2 final fields: `checkHealth`, `checkReady`
///       - `static HealthUseCases build({required HealthContract remote})` factory
///
/// IMPORTANT (RED phase): builder file does not exist yet. Intended RED signal.
library;

// ignore_for_file: unnecessary_type_check

import 'package:test/test.dart';

import 'package:social_care_desktop/src/use_cases/health/check_health_use_case.dart';
import 'package:social_care_desktop/src/use_cases/health/check_ready_use_case.dart';

// ── Builder under test (RED — file does not exist yet) ───────────────
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/facade/composition/builders/health_use_cases.dart';

import '_builders_test_helpers.dart';

void main() {
  group('HealthUseCases', () {
    late BuilderDeps deps;

    setUp(() {
      deps = BuilderDeps.fresh();
      addTearDown(deps.close);
    });

    test(
      'build() returns instance with all 2 fields populated and non-null',
      () {
        final useCases = HealthUseCases.build(remote: deps.healthRemote);

        expect(useCases, isNotNull);
        expect(useCases.checkHealth, isNotNull);
        expect(useCases.checkReady, isNotNull);
      },
    );

    test('each field is the expected concrete UseCase type', () {
      final useCases = HealthUseCases.build(remote: deps.healthRemote);

      expect(useCases.checkHealth, isA<CheckHealthUseCase>());
      expect(useCases.checkReady, isA<CheckReadyUseCase>());
    });

    test(
      'build() called twice with same deps produces independent instances of correct type',
      () {
        final a = HealthUseCases.build(remote: deps.healthRemote);
        final b = HealthUseCases.build(remote: deps.healthRemote);

        expect(identical(a, b), isFalse);
        expect(identical(a.checkHealth, b.checkHealth), isFalse);
        expect(identical(a.checkReady, b.checkReady), isFalse);

        expect(a.checkHealth.runtimeType, equals(b.checkHealth.runtimeType));
        expect(a.checkReady.runtimeType, equals(b.checkReady.runtimeType));
      },
    );
  });
}
