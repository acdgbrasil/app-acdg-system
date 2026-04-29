import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/reject_lookup_request_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/reject_lookup_request_use_case.dart';

import 'test_observability.dart';

/// Forces every call to [LookupContract.rejectLookupRequest] to fail with the
/// configured [BackendError]. Used to validate the failure-path breadcrumb.
class _FailingLookup extends FakeLookupBff {
  _FailingLookup(this.error);
  final BackendError error;

  @override
  Future<Result<StandardResponse<void>>> rejectLookupRequest(
    String requestId,
  ) async => Failure(error);
}

const _intent = RejectLookupRequestIntent(
  requestId: '660e8400-e29b-41d4-a716-446655440001',
);

void main() {
  group('RejectLookupRequestUseCase', () {
    late FakeLookupBff fakeLookup;
    late ObservabilityContext obs;
    late RejectLookupRequestUseCase useCase;

    setUp(() {
      fakeLookup = FakeLookupBff();
      obs = ObservabilityContext.noop();
      useCase = RejectLookupRequestUseCase(lookup: fakeLookup);
    });

    test('returns Success with StandardResponse<void> on happy path', () async {
      final result = await useCase.execute(_intent, obs);

      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test('emits lookup.request.reject.received with requestId', () async {
      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('lookup.request.reject.received', {
            'requestId': '660e8400-e29b-41d4-a716-446655440001',
          }),
        ),
      );
    });

    test('emits lookup.request.reject.completed on success', () async {
      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(hasEvent('lookup.request.reject.completed')),
      );
    });

    test('propagates Failure when lookup.rejectLookupRequest fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'REQUEST_NOT_FOUND',
        message: 'request does not exist',
        http: 404,
      );
      final failing = _FailingLookup(error);
      final useCaseFail = RejectLookupRequestUseCase(lookup: failing);

      final result = await useCaseFail.execute(_intent, obs);

      expect(result, isA<Failure<StandardResponse<void>>>());
    });

    test(
      'emits lookup.request.reject.failed with errorCode on backend failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'REQUEST_NOT_FOUND',
          message: 'request does not exist',
          http: 404,
        );
        final failing = _FailingLookup(error);
        final useCaseFail = RejectLookupRequestUseCase(lookup: failing);

        await useCaseFail.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('lookup.request.reject.failed', {
              'errorCode': 'REQUEST_NOT_FOUND',
            }),
          ),
        );
      },
    );
  });
}
