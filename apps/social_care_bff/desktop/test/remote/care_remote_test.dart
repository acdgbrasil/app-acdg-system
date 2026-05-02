/// RED-phase tests for `CareRemote` (A16-v2).
///
/// `CareRemote implements CareContract`. Two methods:
///   * `registerAppointment(patientId, request)`
///     → `POST /api/v1/patients/{patientId}/appointments` (returns
///       `StandardIdResponse`)
///   * `updateIntakeInfo(patientId, request)`
///     → `PUT /api/v1/patients/{patientId}/intake-info` (returns void)
///
/// Backend paths preserved from legacy `social_care_bff_remote.dart`
/// lines 533-571.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:social_care_desktop/src/remote/care_remote.dart';
import 'package:test/test.dart';

import '../_test_uuids.dart';
import '_mock_dio.dart';

void main() {
  group('CareRemote', () {
    late MockDio dio;
    late CareRemote remote;

    setUp(() {
      dio = MockDio();
      remote = CareRemote(dio: dio);
    });

    test('implements CareContract', () {
      expect(remote, isA<CareContract>());
    });

    group('registerAppointment', () {
      const request = RegisterAppointmentRequest(
        professionalId: kProfessionalUuid,
        summary: 'Initial assessment',
        actionPlan: 'Schedule follow-up',
        date: '2026-04-29',
        type: 'first_visit',
      );

      test('hits POST /api/v1/patients/<id>/appointments with body', () async {
        dio.nextStatusCode = 201;
        dio.nextResponseData = kIdResponseBody(kAppointmentUuid);

        await remote.registerAppointment(kPatientUuid, request);

        expect(dio.lastMethod, equals('POST'));
        expect(
          dio.lastPath,
          equals('/api/v1/patients/$kPatientUuid/appointments'),
        );
        expect(dio.lastBody, equals(request.toJson()));
      });

      test('parses StandardIdResponse on 201', () async {
        dio.nextStatusCode = 201;
        dio.nextResponseData = kIdResponseBody(kAppointmentUuid);

        final result = await remote.registerAppointment(kPatientUuid, request);

        switch (result) {
          case Success(:final value):
            expect(value.data.id, equals(kAppointmentUuid));
          case Failure():
            fail('Expected Success on 201 with valid body');
        }
      });

      test('also accepts 200 for create-on-replay semantics', () async {
        dio.nextStatusCode = 200;
        dio.nextResponseData = kIdResponseBody(kAppointmentUuid);

        final result = await remote.registerAppointment(kPatientUuid, request);

        expect(result, isA<Success<StandardIdResponse>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 422;
          dio.nextResponseData = kBackendErrorBody(
            code: 'APT-422',
            message: 'invalid date',
            http: 422,
          );

          final result = await remote.registerAppointment(
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
                equals('APT-422'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('timeout');

        final result = await remote.registerAppointment(kPatientUuid, request);

        expect(result, isA<Failure<StandardIdResponse>>());
      });
    });

    group('updateIntakeInfo', () {
      const request = RegisterIntakeInfoRequest(
        ingressTypeId: kLookupItemUuid,
        serviceReason: 'Family rebuild',
        originName: 'CRAS Centro',
        originContact: 'unit-test@example.com',
        linkedSocialPrograms: <ProgramLinkDraftDto>[],
      );

      test('hits PUT /api/v1/patients/<id>/intake-info with body', () async {
        dio.nextStatusCode = 204;

        await remote.updateIntakeInfo(kPatientUuid, request);

        expect(dio.lastMethod, equals('PUT'));
        expect(
          dio.lastPath,
          equals('/api/v1/patients/$kPatientUuid/intake-info'),
        );
        expect(dio.lastBody, equals(request.toJson()));
      });

      test('returns Success(null) on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.updateIntakeInfo(kPatientUuid, request);

        expect(result, isA<Success<void>>());
      });

      test('also accepts 200 for idempotent updates', () async {
        dio.nextStatusCode = 200;

        final result = await remote.updateIntakeInfo(kPatientUuid, request);

        expect(result, isA<Success<void>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 400;
          dio.nextResponseData = kBackendErrorBody(
            code: 'INT-400',
            message: 'serviceReason required',
            http: 400,
          );

          final result = await remote.updateIntakeInfo(kPatientUuid, request);

          switch (result) {
            case Success():
              fail('Expected Failure on 400');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('INT-400'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('connection reset');

        final result = await remote.updateIntakeInfo(kPatientUuid, request);

        expect(result, isA<Failure<void>>());
      });
    });
  });
}
