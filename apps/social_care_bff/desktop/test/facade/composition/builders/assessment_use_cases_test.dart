/// RED-phase tests for `AssessmentUseCases` builder (D02 W0.5).
///
/// `AssessmentUseCases` groups the 7 Assessment write use cases — all of
/// them are Pattern-2 writes against `PatientsCache` (the social-health
/// fichas live embedded in the Patient aggregate, A18b-v2). Today they
/// are listed inline in `social_care_desktop.dart` (lines 372-413).
///
/// ── Surface under test ───────────────────────────────────────────────
///   * `class AssessmentUseCases`
///       - 7 final fields: `updateHealthStatus`, `updateHousingCondition`,
///         `updateEducationalStatus`, `updateSocioEconomicSituation`,
///         `updateWorkAndIncome`, `updateCommunitySupportNetwork`,
///         `updateSocialHealthSummary`
///       - `static AssessmentUseCases build({...})` factory
///
/// Per the ticket spec (D02 000-request.md), Assessment's `build()` does
/// NOT need a `remote:` parameter — none of its 7 use cases consume an
/// `AssessmentContract` (writes go via Outbox + SyncEngine; the
/// AssessmentRemote is exercised by the engine's drain, not by the use
/// case). It DOES still need `patientsCache`, `outbox`, `engine`, `clock`.
///
/// IMPORTANT (RED phase): `lib/src/facade/composition/builders/assessment_use_cases.dart`
/// does not exist yet — the import below fails. Intended RED signal.
library;

// ignore_for_file: unnecessary_type_check

import 'package:test/test.dart';

import 'package:social_care_desktop/src/use_cases/assessment/update_community_support_network_use_case.dart';
import 'package:social_care_desktop/src/use_cases/assessment/update_educational_status_use_case.dart';
import 'package:social_care_desktop/src/use_cases/assessment/update_health_status_use_case.dart';
import 'package:social_care_desktop/src/use_cases/assessment/update_housing_condition_use_case.dart';
import 'package:social_care_desktop/src/use_cases/assessment/update_social_health_summary_use_case.dart';
import 'package:social_care_desktop/src/use_cases/assessment/update_socio_economic_situation_use_case.dart';
import 'package:social_care_desktop/src/use_cases/assessment/update_work_and_income_use_case.dart';

// ── Builder under test (RED — file does not exist yet) ───────────────
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/facade/composition/builders/assessment_use_cases.dart';

import '_builders_test_helpers.dart';

void main() {
  group('AssessmentUseCases', () {
    late BuilderDeps deps;

    setUp(() {
      deps = BuilderDeps.fresh();
      addTearDown(deps.close);
    });

    test(
      'build() returns instance with all 7 fields populated and non-null',
      () {
        final useCases = AssessmentUseCases.build(
          patientsCache: deps.patientsCache,
          outbox: deps.outbox,
          engine: deps.engine,
          clock: deps.clock,
        );

        expect(useCases, isNotNull);
        expect(useCases.updateHealthStatus, isNotNull);
        expect(useCases.updateHousingCondition, isNotNull);
        expect(useCases.updateEducationalStatus, isNotNull);
        expect(useCases.updateSocioEconomicSituation, isNotNull);
        expect(useCases.updateWorkAndIncome, isNotNull);
        expect(useCases.updateCommunitySupportNetwork, isNotNull);
        expect(useCases.updateSocialHealthSummary, isNotNull);
      },
    );

    test('each field is the expected concrete UseCase type', () {
      final useCases = AssessmentUseCases.build(
        patientsCache: deps.patientsCache,
        outbox: deps.outbox,
        engine: deps.engine,
        clock: deps.clock,
      );

      expect(useCases.updateHealthStatus, isA<UpdateHealthStatusUseCase>());
      expect(
        useCases.updateHousingCondition,
        isA<UpdateHousingConditionUseCase>(),
      );
      expect(
        useCases.updateEducationalStatus,
        isA<UpdateEducationalStatusUseCase>(),
      );
      expect(
        useCases.updateSocioEconomicSituation,
        isA<UpdateSocioEconomicSituationUseCase>(),
      );
      expect(useCases.updateWorkAndIncome, isA<UpdateWorkAndIncomeUseCase>());
      expect(
        useCases.updateCommunitySupportNetwork,
        isA<UpdateCommunitySupportNetworkUseCase>(),
      );
      expect(
        useCases.updateSocialHealthSummary,
        isA<UpdateSocialHealthSummaryUseCase>(),
      );
    });

    test(
      'build() called twice with same deps produces independent instances of correct type',
      () {
        final a = AssessmentUseCases.build(
          patientsCache: deps.patientsCache,
          outbox: deps.outbox,
          engine: deps.engine,
          clock: deps.clock,
        );
        final b = AssessmentUseCases.build(
          patientsCache: deps.patientsCache,
          outbox: deps.outbox,
          engine: deps.engine,
          clock: deps.clock,
        );

        expect(identical(a, b), isFalse);
        expect(identical(a.updateHealthStatus, b.updateHealthStatus), isFalse);
        expect(
          identical(a.updateSocialHealthSummary, b.updateSocialHealthSummary),
          isFalse,
        );

        expect(
          a.updateHealthStatus.runtimeType,
          equals(b.updateHealthStatus.runtimeType),
        );
        expect(
          a.updateSocialHealthSummary.runtimeType,
          equals(b.updateSocialHealthSummary.runtimeType),
        );
      },
    );
  });
}
