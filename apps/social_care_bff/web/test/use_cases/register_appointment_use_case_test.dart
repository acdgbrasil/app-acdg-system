import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/register_appointment_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/register_appointment_use_case.dart';

import 'test_observability.dart';

/// Forces every call to [CareContract.registerAppointment] to fail with the
/// configured [BackendError]. Used to validate the failure-path breadcrumb.
class _FailingCare extends FakeCareBff {
  _FailingCare(this.error);
  final BackendError error;

  @override
  Future<Result<StandardIdResponse>> registerAppointment(
    String patientId,
    RegisterAppointmentRequest request,
  ) async => Failure(error);
}

const _request = RegisterAppointmentRequest(
  professionalId: 'prof-42',
  summary: 'Primeira consulta',
  actionPlan: 'Encaminhar',
  date: '2026-04-17T10:00:00Z',
  type: 'intake',
);

const _intent = RegisterAppointmentIntent(
  patientId: 'pat-1',
  request: _request,
);

void main() {
  group('RegisterAppointmentUseCase', () {
    late FakeCareBff fakeCare;
    late ObservabilityContext obs;
    late RegisterAppointmentUseCase useCase;

    setUp(() {
      fakeCare = FakeCareBff();
      obs = ObservabilityContext.noop();
      useCase = RegisterAppointmentUseCase(care: fakeCare);
    });

    test('returns Success with StandardIdResponse on happy path', () async {
      final result = await useCase.execute(_intent, obs);

      expect(result, isA<Success<StandardIdResponse>>());
      switch (result) {
        case Success(:final value):
          expect(value.data.id, isNotEmpty);
        case Failure():
          fail('Expected Success');
      }
    });

    test('persists appointment on the fake store (side-effect)', () async {
      await useCase.execute(_intent, obs);

      expect(fakeCare.store.appointments['pat-1'], isNotNull);
      expect(fakeCare.store.appointments['pat-1'], hasLength(1));
    });

    test(
      'emits care.appointment.register.received with patientId only',
      () async {
        await useCase.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('care.appointment.register.received', {
              'patientId': 'pat-1',
            }),
          ),
        );
      },
    );

    test('emits care.appointment.register.completed on success', () async {
      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(hasEvent('care.appointment.register.completed')),
      );
    });

    test(
      '.completed breadcrumb carries appointmentId (non-PII UUID)',
      () async {
        final result = await useCase.execute(_intent, obs);

        final expectedId = switch (result) {
          Success(:final value) => value.data.id,
          Failure() => fail('Expected Success'),
        };

        final completed = obs.breadcrumbs.firstWhere(
          (b) => b.event == 'care.appointment.register.completed',
        );
        expect(completed.data['appointmentId'], equals(expectedId));
      },
    );

    test('propagates Failure when care.registerAppointment fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'INVALID_PROFESSIONAL',
        message: 'professional not found',
        http: 422,
      );
      final failing = _FailingCare(error);
      final useCaseFail = RegisterAppointmentUseCase(care: failing);

      final result = await useCaseFail.execute(_intent, obs);

      expect(result, isA<Failure<StandardIdResponse>>());
    });

    test('emits care.appointment.register.failed on backend failure', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'INVALID_PROFESSIONAL',
        message: 'professional not found',
        http: 422,
      );
      final failing = _FailingCare(error);
      final useCaseFail = RegisterAppointmentUseCase(care: failing);

      await useCaseFail.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('care.appointment.register.failed', {
            'errorCode': 'INVALID_PROFESSIONAL',
          }),
        ),
      );
    });

    test(
      'breadcrumbs NEVER echo raw summary / actionPlan (PII canon)',
      () async {
        await useCase.execute(_intent, obs);

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString();
          expect(
            dumped,
            isNot(contains('Primeira consulta')),
            reason: 'summary must not surface in breadcrumb data',
          );
          expect(
            dumped,
            isNot(contains('Encaminhar')),
            reason: 'actionPlan must not surface in breadcrumb data',
          );
        }
      },
    );
  });
}
