/// RED-phase tests for `AssessmentRemote` (A16-v2).
///
/// `AssessmentRemote implements AssessmentContract`. Seven methods, each
/// a thin PUT to a specific path under `/api/v1/patients/{patientId}/`:
///   * `updateHousingCondition`        → `housing-condition`
///   * `updateSocioEconomicSituation`  → `socioeconomic-situation`
///   * `updateWorkAndIncome`           → `work-and-income`
///   * `updateEducationalStatus`       → `educational-status`
///   * `updateHealthStatus`            → `health-status`
///   * `updateCommunitySupportNetwork` → `community-support-network`
///   * `updateSocialHealthSummary`     → `social-health-summary`
///
/// All return `Future<Result<void>>` — `Success(null)` on 2xx, error
/// mapping otherwise. Backend paths preserved from legacy
/// `social_care_bff_remote.dart` lines 383-529.
///
/// Per method we test 5 axes: HTTP path, body mapping, success, backend
/// error, and Dio throw. We deliberately don't multiply test counts
/// across all 7 methods for the success-on-200 branch — once per method
/// is enough since that path is identical.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:social_care_desktop/src/remote/assessment_remote.dart';
import 'package:test/test.dart';

import '../_test_uuids.dart';
import '_mock_dio.dart';

void main() {
  group('AssessmentRemote', () {
    late MockDio dio;
    late AssessmentRemote remote;

    setUp(() {
      dio = MockDio();
      remote = AssessmentRemote(dio: dio);
    });

    test('implements AssessmentContract', () {
      expect(remote, isA<AssessmentContract>());
    });

    // ── updateHousingCondition ────────────────────────────────────────
    group('updateHousingCondition', () {
      const request = UpdateHousingConditionRequest(
        type: 'apartment',
        wallMaterial: 'masonry',
        numberOfRooms: 4,
        numberOfBedrooms: 2,
        numberOfBathrooms: 1,
        waterSupply: 'public',
        hasPipedWater: true,
        electricityAccess: 'public',
        sewageDisposal: 'public',
        wasteCollection: 'weekly',
        accessibilityLevel: 'partial',
        isInGeographicRiskArea: false,
        hasDifficultAccess: false,
        isInSocialConflictArea: false,
        hasDiagnosticObservations: false,
      );

      test(
        'hits PUT /api/v1/patients/<id>/housing-condition with body',
        () async {
          dio.nextStatusCode = 204;

          await remote.updateHousingCondition(kPatientUuid, request);

          expect(dio.lastMethod, equals('PUT'));
          expect(
            dio.lastPath,
            equals('/api/v1/patients/$kPatientUuid/housing-condition'),
          );
          expect(dio.lastBody, equals(request.toJson()));
        },
      );

      test('returns Success(null) on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.updateHousingCondition(
          kPatientUuid,
          request,
        );

        expect(result, isA<Success<void>>());
      });

      test('also accepts 200 for idempotent updates', () async {
        dio.nextStatusCode = 200;

        final result = await remote.updateHousingCondition(
          kPatientUuid,
          request,
        );

        expect(result, isA<Success<void>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 422;
          dio.nextResponseData = kBackendErrorBody(
            code: 'HOU-422',
            message: 'invalid wall material',
            http: 422,
          );

          final result = await remote.updateHousingCondition(
            kPatientUuid,
            request,
          );

          switch (result) {
            case Success():
              fail('Expected Failure on 422');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('HOU-422'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('timeout');

        final result = await remote.updateHousingCondition(
          kPatientUuid,
          request,
        );

        expect(result, isA<Failure<void>>());
      });
    });

    // ── updateSocioEconomicSituation ──────────────────────────────────
    group('updateSocioEconomicSituation', () {
      const request = UpdateSocioEconomicSituationRequest(
        totalFamilyIncome: 1500.0,
        incomePerCapita: 500.0,
        receivesSocialBenefit: true,
        mainSourceOfIncome: 'formal_work',
        hasUnemployed: false,
        socialBenefits: <SocialBenefitDraftDto>[],
      );

      test(
        'hits PUT /api/v1/patients/<id>/socioeconomic-situation with body',
        () async {
          dio.nextStatusCode = 204;

          await remote.updateSocioEconomicSituation(kPatientUuid, request);

          expect(dio.lastMethod, equals('PUT'));
          expect(
            dio.lastPath,
            equals('/api/v1/patients/$kPatientUuid/socioeconomic-situation'),
          );
          expect(dio.lastBody, equals(request.toJson()));
        },
      );

      test('returns Success(null) on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.updateSocioEconomicSituation(
          kPatientUuid,
          request,
        );

        expect(result, isA<Success<void>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 400;
          dio.nextResponseData = kBackendErrorBody(
            code: 'SES-400',
            message: 'income mismatch',
            http: 400,
          );

          final result = await remote.updateSocioEconomicSituation(
            kPatientUuid,
            request,
          );

          switch (result) {
            case Success():
              fail('Expected Failure on 400');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('SES-400'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('boom');

        final result = await remote.updateSocioEconomicSituation(
          kPatientUuid,
          request,
        );

        expect(result, isA<Failure<void>>());
      });
    });

    // ── updateWorkAndIncome ───────────────────────────────────────────
    group('updateWorkAndIncome', () {
      const request = UpdateWorkAndIncomeRequest(
        hasRetiredMembers: false,
        individualIncomes: <IncomeDraftDto>[],
        socialBenefits: <SocialBenefitDraftDto>[],
      );

      test(
        'hits PUT /api/v1/patients/<id>/work-and-income with body',
        () async {
          dio.nextStatusCode = 204;

          await remote.updateWorkAndIncome(kPatientUuid, request);

          expect(dio.lastMethod, equals('PUT'));
          expect(
            dio.lastPath,
            equals('/api/v1/patients/$kPatientUuid/work-and-income'),
          );
          expect(dio.lastBody, equals(request.toJson()));
        },
      );

      test('returns Success(null) on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.updateWorkAndIncome(kPatientUuid, request);

        expect(result, isA<Success<void>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 400;
          dio.nextResponseData = kBackendErrorBody(
            code: 'WAI-400',
            message: 'invalid income',
            http: 400,
          );

          final result = await remote.updateWorkAndIncome(
            kPatientUuid,
            request,
          );

          switch (result) {
            case Success():
              fail('Expected Failure on 400');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('WAI-400'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('reset');

        final result = await remote.updateWorkAndIncome(kPatientUuid, request);

        expect(result, isA<Failure<void>>());
      });
    });

    // ── updateEducationalStatus ───────────────────────────────────────
    group('updateEducationalStatus', () {
      const request = UpdateEducationalStatusRequest(
        memberProfiles: <ProfileDraftDto>[],
        programOccurrences: <OccurrenceDraftDto>[],
      );

      test(
        'hits PUT /api/v1/patients/<id>/educational-status with body',
        () async {
          dio.nextStatusCode = 204;

          await remote.updateEducationalStatus(kPatientUuid, request);

          expect(dio.lastMethod, equals('PUT'));
          expect(
            dio.lastPath,
            equals('/api/v1/patients/$kPatientUuid/educational-status'),
          );
          expect(dio.lastBody, equals(request.toJson()));
        },
      );

      test('returns Success(null) on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.updateEducationalStatus(
          kPatientUuid,
          request,
        );

        expect(result, isA<Success<void>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 400;
          dio.nextResponseData = kBackendErrorBody(
            code: 'EDU-400',
            message: 'unknown profile',
            http: 400,
          );

          final result = await remote.updateEducationalStatus(
            kPatientUuid,
            request,
          );

          switch (result) {
            case Success():
              fail('Expected Failure on 400');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('EDU-400'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('eof');

        final result = await remote.updateEducationalStatus(
          kPatientUuid,
          request,
        );

        expect(result, isA<Failure<void>>());
      });
    });

    // ── updateHealthStatus ────────────────────────────────────────────
    group('updateHealthStatus', () {
      const request = UpdateHealthStatusRequest(
        foodInsecurity: false,
        deficiencies: <DeficiencyDraftDto>[],
        gestatingMembers: <PregnantDraftDto>[],
        constantCareNeeds: <String>[],
      );

      test('hits PUT /api/v1/patients/<id>/health-status with body', () async {
        dio.nextStatusCode = 204;

        await remote.updateHealthStatus(kPatientUuid, request);

        expect(dio.lastMethod, equals('PUT'));
        expect(
          dio.lastPath,
          equals('/api/v1/patients/$kPatientUuid/health-status'),
        );
        expect(dio.lastBody, equals(request.toJson()));
      });

      test('returns Success(null) on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.updateHealthStatus(kPatientUuid, request);

        expect(result, isA<Success<void>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 400;
          dio.nextResponseData = kBackendErrorBody(
            code: 'HEA-400',
            message: 'invalid deficiency',
            http: 400,
          );

          final result = await remote.updateHealthStatus(kPatientUuid, request);

          switch (result) {
            case Success():
              fail('Expected Failure on 400');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('HEA-400'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('timeout');

        final result = await remote.updateHealthStatus(kPatientUuid, request);

        expect(result, isA<Failure<void>>());
      });
    });

    // ── updateCommunitySupportNetwork ─────────────────────────────────
    group('updateCommunitySupportNetwork', () {
      const request = UpdateCommunitySupportNetworkRequest(
        hasRelativeSupport: true,
        hasNeighborSupport: false,
        familyConflicts: 'none',
        patientParticipatesInGroups: false,
        familyParticipatesInGroups: false,
        patientHasAccessToLeisure: true,
        facesDiscrimination: false,
      );

      test(
        'hits PUT /api/v1/patients/<id>/community-support-network with body',
        () async {
          dio.nextStatusCode = 204;

          await remote.updateCommunitySupportNetwork(kPatientUuid, request);

          expect(dio.lastMethod, equals('PUT'));
          expect(
            dio.lastPath,
            equals('/api/v1/patients/$kPatientUuid/community-support-network'),
          );
          expect(dio.lastBody, equals(request.toJson()));
        },
      );

      test('returns Success(null) on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.updateCommunitySupportNetwork(
          kPatientUuid,
          request,
        );

        expect(result, isA<Success<void>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 400;
          dio.nextResponseData = kBackendErrorBody(
            code: 'CSN-400',
            message: 'invalid familyConflicts',
            http: 400,
          );

          final result = await remote.updateCommunitySupportNetwork(
            kPatientUuid,
            request,
          );

          switch (result) {
            case Success():
              fail('Expected Failure on 400');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('CSN-400'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('reset');

        final result = await remote.updateCommunitySupportNetwork(
          kPatientUuid,
          request,
        );

        expect(result, isA<Failure<void>>());
      });
    });

    // ── updateSocialHealthSummary ─────────────────────────────────────
    group('updateSocialHealthSummary', () {
      const request = UpdateSocialHealthSummaryRequest(
        requiresConstantCare: false,
        hasMobilityImpairment: false,
        hasRelevantDrugTherapy: false,
        functionalDependencies: <String>[],
      );

      test(
        'hits PUT /api/v1/patients/<id>/social-health-summary with body',
        () async {
          dio.nextStatusCode = 204;

          await remote.updateSocialHealthSummary(kPatientUuid, request);

          expect(dio.lastMethod, equals('PUT'));
          expect(
            dio.lastPath,
            equals('/api/v1/patients/$kPatientUuid/social-health-summary'),
          );
          expect(dio.lastBody, equals(request.toJson()));
        },
      );

      test('returns Success(null) on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.updateSocialHealthSummary(
          kPatientUuid,
          request,
        );

        expect(result, isA<Success<void>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 422;
          dio.nextResponseData = kBackendErrorBody(
            code: 'SHS-422',
            message: 'inconsistent flags',
            http: 422,
          );

          final result = await remote.updateSocialHealthSummary(
            kPatientUuid,
            request,
          );

          switch (result) {
            case Success():
              fail('Expected Failure on 422');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('SHS-422'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('boom');

        final result = await remote.updateSocialHealthSummary(
          kPatientUuid,
          request,
        );

        expect(result, isA<Failure<void>>());
      });
    });
  });
}
