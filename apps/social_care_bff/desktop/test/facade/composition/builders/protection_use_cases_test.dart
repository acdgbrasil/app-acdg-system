/// RED-phase tests for `ProtectionUseCases` builder (D02 W0.5).
///
/// `ProtectionUseCases` groups the 6 Protection use cases:
///   * `CreateReferralUseCase`        — write, outbox + engine
///   * `ListReferralsUseCase`         — read, `protectionCache` only
///   * `ReportViolationUseCase`       — write, outbox + engine
///   * `ListViolationReportsUseCase`  — read, `protectionCache` only
///   * `FetchPlacementHistoryUseCase` — read, `protectionCache` only
///   * `UpdatePlacementHistoryUseCase`— write, `patientsCache` (placement
///                                      history lives on Patient aggregate)
///                                      + outbox + engine
///
/// So Protection's `build()` takes BOTH `protectionCache` and
/// `patientsCache`, plus outbox/engine/clock/staleAfter. No `remote:`
/// param — Protection writes go via Outbox (engine drains), reads use
/// the cache only (Phase 5 backend doesn't expose protection list/get
/// endpoints; the staleAfter is accepted for Pattern-1 uniformity per H3).
///
/// ── Surface under test ───────────────────────────────────────────────
///   * `class ProtectionUseCases`
///       - 6 final fields: `createReferral`, `listReferrals`,
///         `reportViolation`, `listViolationReports`,
///         `fetchPlacementHistory`, `updatePlacementHistory`
///       - `static ProtectionUseCases build({...})` factory
///
/// IMPORTANT (RED phase): builder file does not exist yet. Intended RED signal.
library;

// ignore_for_file: unnecessary_type_check

import 'package:test/test.dart';

import 'package:social_care_desktop/src/use_cases/protection/create_referral_use_case.dart';
import 'package:social_care_desktop/src/use_cases/protection/fetch_placement_history_use_case.dart';
import 'package:social_care_desktop/src/use_cases/protection/list_referrals_use_case.dart';
import 'package:social_care_desktop/src/use_cases/protection/list_violation_reports_use_case.dart';
import 'package:social_care_desktop/src/use_cases/protection/report_violation_use_case.dart';
import 'package:social_care_desktop/src/use_cases/protection/update_placement_history_use_case.dart';

// ── Builder under test (RED — file does not exist yet) ───────────────
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/facade/composition/builders/protection_use_cases.dart';

import '_builders_test_helpers.dart';

void main() {
  group('ProtectionUseCases', () {
    late BuilderDeps deps;

    setUp(() {
      deps = BuilderDeps.fresh();
      addTearDown(deps.close);
    });

    test(
      'build() returns instance with all 6 fields populated and non-null',
      () {
        final useCases = ProtectionUseCases.build(
          protectionCache: deps.protectionCache,
          patientsCache: deps.patientsCache,
          outbox: deps.outbox,
          engine: deps.engine,
          clock: deps.clock,
          staleAfter: deps.staleAfter,
        );

        expect(useCases, isNotNull);
        expect(useCases.createReferral, isNotNull);
        expect(useCases.listReferrals, isNotNull);
        expect(useCases.reportViolation, isNotNull);
        expect(useCases.listViolationReports, isNotNull);
        expect(useCases.fetchPlacementHistory, isNotNull);
        expect(useCases.updatePlacementHistory, isNotNull);
      },
    );

    test('each field is the expected concrete UseCase type', () {
      final useCases = ProtectionUseCases.build(
        protectionCache: deps.protectionCache,
        patientsCache: deps.patientsCache,
        outbox: deps.outbox,
        engine: deps.engine,
        clock: deps.clock,
        staleAfter: deps.staleAfter,
      );

      expect(useCases.createReferral, isA<CreateReferralUseCase>());
      expect(useCases.listReferrals, isA<ListReferralsUseCase>());
      expect(useCases.reportViolation, isA<ReportViolationUseCase>());
      expect(useCases.listViolationReports, isA<ListViolationReportsUseCase>());
      expect(
        useCases.fetchPlacementHistory,
        isA<FetchPlacementHistoryUseCase>(),
      );
      expect(
        useCases.updatePlacementHistory,
        isA<UpdatePlacementHistoryUseCase>(),
      );
    });

    test(
      'build() called twice with same deps produces independent instances of correct type',
      () {
        final a = ProtectionUseCases.build(
          protectionCache: deps.protectionCache,
          patientsCache: deps.patientsCache,
          outbox: deps.outbox,
          engine: deps.engine,
          clock: deps.clock,
          staleAfter: deps.staleAfter,
        );
        final b = ProtectionUseCases.build(
          protectionCache: deps.protectionCache,
          patientsCache: deps.patientsCache,
          outbox: deps.outbox,
          engine: deps.engine,
          clock: deps.clock,
          staleAfter: deps.staleAfter,
        );

        expect(identical(a, b), isFalse);
        expect(identical(a.createReferral, b.createReferral), isFalse);
        expect(identical(a.listReferrals, b.listReferrals), isFalse);
        expect(
          identical(a.updatePlacementHistory, b.updatePlacementHistory),
          isFalse,
        );

        expect(
          a.createReferral.runtimeType,
          equals(b.createReferral.runtimeType),
        );
        expect(
          a.listReferrals.runtimeType,
          equals(b.listReferrals.runtimeType),
        );
        expect(
          a.updatePlacementHistory.runtimeType,
          equals(b.updatePlacementHistory.runtimeType),
        );
      },
    );
  });
}
