/// RED-phase tests for `AuditUseCases` builder (D02 W0.5).
///
/// `AuditUseCases` groups the single Audit use case:
///   * `FetchAuditTrailUseCase` — read, `auditCache` + `auditRemote`
///                                + clock + staleAfter (Pattern 1)
///
/// Yes — a builder for ONE use case. The point isn't economy, it's
/// **uniformity**: when D03/D6 add `RecordAuditEventUseCase` (planned),
/// `social_care_desktop.dart` doesn't change — only `AuditUseCases` does.
/// Three tests still apply because they pin the structural contract
/// (build returns instance, field types match, factory not singleton).
///
/// ── Surface under test ───────────────────────────────────────────────
///   * `class AuditUseCases`
///       - 1 final field: `fetchAuditTrail`
///       - `static AuditUseCases build({...})` factory
///
/// IMPORTANT (RED phase): builder file does not exist yet. Intended RED signal.
library;

// ignore_for_file: unnecessary_type_check

import 'package:test/test.dart';

import 'package:social_care_desktop/src/use_cases/audit/fetch_audit_trail_use_case.dart';

// ── Builder under test (RED — file does not exist yet) ───────────────
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/facade/composition/builders/audit_use_cases.dart';

import '_builders_test_helpers.dart';

void main() {
  group('AuditUseCases', () {
    late BuilderDeps deps;

    setUp(() {
      deps = BuilderDeps.fresh();
      addTearDown(deps.close);
    });

    test(
      'build() returns instance with all 1 field populated and non-null',
      () {
        final useCases = AuditUseCases.build(
          auditCache: deps.auditCache,
          remote: deps.auditRemote,
          clock: deps.clock,
          staleAfter: deps.staleAfter,
        );

        expect(useCases, isNotNull);
        expect(useCases.fetchAuditTrail, isNotNull);
      },
    );

    test('each field is the expected concrete UseCase type', () {
      final useCases = AuditUseCases.build(
        auditCache: deps.auditCache,
        remote: deps.auditRemote,
        clock: deps.clock,
        staleAfter: deps.staleAfter,
      );

      expect(useCases.fetchAuditTrail, isA<FetchAuditTrailUseCase>());
    });

    test(
      'build() called twice with same deps produces independent instances of correct type',
      () {
        final a = AuditUseCases.build(
          auditCache: deps.auditCache,
          remote: deps.auditRemote,
          clock: deps.clock,
          staleAfter: deps.staleAfter,
        );
        final b = AuditUseCases.build(
          auditCache: deps.auditCache,
          remote: deps.auditRemote,
          clock: deps.clock,
          staleAfter: deps.staleAfter,
        );

        expect(identical(a, b), isFalse);
        expect(identical(a.fetchAuditTrail, b.fetchAuditTrail), isFalse);
        expect(
          a.fetchAuditTrail.runtimeType,
          equals(b.fetchAuditTrail.runtimeType),
        );
      },
    );
  });
}
