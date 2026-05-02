/// RED-phase tests for `ProtectionRemote` (A16-v2).
///
/// `ProtectionRemote implements ProtectionContract`. Three methods:
///   * `updatePlacementHistory(patientId, request)`
///     → `PUT /api/v1/patients/{patientId}/placement-history` (void)
///   * `reportViolation(patientId, request)`
///     → `POST /api/v1/patients/{patientId}/violation-reports`
///       (`StandardIdResponse`)
///   * `createReferral(patientId, request)`
///     → `POST /api/v1/patients/{patientId}/referrals`
///       (`StandardIdResponse`)
///
/// Backend paths preserved from legacy `social_care_bff_remote.dart`
/// lines 575-633.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:social_care_desktop/src/remote/protection_remote.dart';
import 'package:test/test.dart';

import '../_test_uuids.dart';
import '_mock_dio.dart';

void main() {
  group('ProtectionRemote', () {
    late MockDio dio;
    late ProtectionRemote remote;

    setUp(() {
      dio = MockDio();
      remote = ProtectionRemote(dio: dio);
    });

    test('implements ProtectionContract', () {
      expect(remote, isA<ProtectionContract>());
    });

    group('updatePlacementHistory', () {
      const request = UpdatePlacementHistoryRequest(
        registries: <RegistryDraftDto>[],
        collectiveSituations: CollectiveDraftDto(),
        separationChecklist: SeparationDraftDto(),
      );

      test(
        'hits PUT /api/v1/patients/<id>/placement-history with body',
        () async {
          dio.nextStatusCode = 204;

          await remote.updatePlacementHistory(kPatientUuid, request);

          expect(dio.lastMethod, equals('PUT'));
          expect(
            dio.lastPath,
            equals('/api/v1/patients/$kPatientUuid/placement-history'),
          );
          expect(dio.lastBody, equals(request.toJson()));
        },
      );

      test('returns Success(null) on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.updatePlacementHistory(
          kPatientUuid,
          request,
        );

        expect(result, isA<Success<void>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 409;
          dio.nextResponseData = kBackendErrorBody(
            code: 'PROT-409',
            message: 'conflict',
            http: 409,
          );

          final result = await remote.updatePlacementHistory(
            kPatientUuid,
            request,
          );

          switch (result) {
            case Success():
              fail('Expected Failure on 409');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('PROT-409'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('eof');

        final result = await remote.updatePlacementHistory(
          kPatientUuid,
          request,
        );

        expect(result, isA<Failure<void>>());
      });
    });

    group('reportViolation', () {
      const request = ReportRightsViolationRequest(
        victimId: kPersonUuid,
        violationType: 'physical',
        descriptionOfFact: 'Reported by neighbor',
        violationTypeId: kLookupItemUuid,
        reportDate: '2026-04-29',
        incidentDate: '2026-04-28',
        actionsTaken: 'Notified guardian council',
      );

      test(
        'hits POST /api/v1/patients/<id>/violation-reports with body',
        () async {
          dio.nextStatusCode = 201;
          dio.nextResponseData = kIdResponseBody(kViolationReportUuid);

          await remote.reportViolation(kPatientUuid, request);

          expect(dio.lastMethod, equals('POST'));
          expect(
            dio.lastPath,
            equals('/api/v1/patients/$kPatientUuid/violation-reports'),
          );
          expect(dio.lastBody, equals(request.toJson()));
        },
      );

      test('parses StandardIdResponse on 201', () async {
        dio.nextStatusCode = 201;
        dio.nextResponseData = kIdResponseBody(kViolationReportUuid);

        final result = await remote.reportViolation(kPatientUuid, request);

        switch (result) {
          case Success(:final value):
            expect(value.data.id, equals(kViolationReportUuid));
          case Failure():
            fail('Expected Success on 201 with valid body');
        }
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 400;
          dio.nextResponseData = kBackendErrorBody(
            code: 'VIO-400',
            message: 'description required',
            http: 400,
          );

          final result = await remote.reportViolation(kPatientUuid, request);

          switch (result) {
            case Success():
              fail('Expected Failure on 400');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('VIO-400'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('boom');

        final result = await remote.reportViolation(kPatientUuid, request);

        expect(result, isA<Failure<StandardIdResponse>>());
      });
    });

    group('createReferral', () {
      const request = CreateReferralRequest(
        referredPersonId: kPersonUuid,
        destinationService: 'CAPS',
        reason: 'Mental health follow-up',
        professionalId: kProfessionalUuid,
        date: '2026-04-29',
      );

      test('hits POST /api/v1/patients/<id>/referrals with body', () async {
        dio.nextStatusCode = 201;
        dio.nextResponseData = kIdResponseBody(kReferralUuid);

        await remote.createReferral(kPatientUuid, request);

        expect(dio.lastMethod, equals('POST'));
        expect(
          dio.lastPath,
          equals('/api/v1/patients/$kPatientUuid/referrals'),
        );
        expect(dio.lastBody, equals(request.toJson()));
      });

      test('parses StandardIdResponse on 201', () async {
        dio.nextStatusCode = 201;
        dio.nextResponseData = kIdResponseBody(kReferralUuid);

        final result = await remote.createReferral(kPatientUuid, request);

        switch (result) {
          case Success(:final value):
            expect(value.data.id, equals(kReferralUuid));
          case Failure():
            fail('Expected Success on 201 with valid body');
        }
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 422;
          dio.nextResponseData = kBackendErrorBody(
            code: 'REF-422',
            message: 'destinationService unknown',
            http: 422,
          );

          final result = await remote.createReferral(kPatientUuid, request);

          switch (result) {
            case Success():
              fail('Expected Failure on 422');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('REF-422'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('reset by peer');

        final result = await remote.createReferral(kPatientUuid, request);

        expect(result, isA<Failure<StandardIdResponse>>());
      });
    });
  });
}
