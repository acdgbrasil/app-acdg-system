import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/get_lookup_requests_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/get_lookup_requests_use_case.dart';

import 'test_observability.dart';

/// Forces every call to [LookupContract.getLookupRequests] to fail with the
/// configured [BackendError]. Used to validate the failure-path breadcrumb.
class _FailingLookup extends FakeLookupBff {
  _FailingLookup(this.error);
  final BackendError error;

  @override
  Future<Result<StandardResponse<List<LookupRequestResponse>>>>
  getLookupRequests() async => Failure(error);
}

const _intent = GetLookupRequestsIntent();

LookupRequestResponse _seedRequest({required String id}) =>
    LookupRequestResponse(
      id: id,
      tableName: 'dominio_diagnostico',
      codigo: 'WILLIAMS',
      descricao: 'Sindrome de Williams',
      justificativa: 'raro',
      status: 'pending',
      createdAt: '2026-04-17T10:00:00Z',
      requestedBy: 'user-42',
    );

void main() {
  group('GetLookupRequestsUseCase', () {
    late FakeLookupBff fakeLookup;
    late ObservabilityContext obs;
    late GetLookupRequestsUseCase useCase;

    setUp(() {
      fakeLookup = FakeLookupBff();
      obs = ObservabilityContext.noop();
      useCase = GetLookupRequestsUseCase(lookup: fakeLookup);
    });

    test('returns Success with empty list when nothing is stored', () async {
      final result = await useCase.execute(_intent, obs);

      expect(
        result,
        isA<Success<StandardResponse<List<LookupRequestResponse>>>>(),
      );
      switch (result) {
        case Success(:final value):
          expect(value.data, isEmpty);
        case Failure():
          fail('Expected Success');
      }
    });

    test('returns all seeded requests', () async {
      fakeLookup.store.addRequest(_seedRequest(id: 'r-1'));
      fakeLookup.store.addRequest(_seedRequest(id: 'r-2'));

      final result = await useCase.execute(_intent, obs);

      switch (result) {
        case Success(:final value):
          expect(value.data, hasLength(2));
        case Failure():
          fail('Expected Success');
      }
    });

    test('emits lookup.request.list.received without data', () async {
      await useCase.execute(_intent, obs);

      final received = obs.breadcrumbs.firstWhere(
        (b) => b.event == 'lookup.request.list.received',
      );
      expect(received.data, isEmpty);
    });

    test('emits lookup.request.list.completed with count on success', () async {
      fakeLookup.store.addRequest(_seedRequest(id: 'r-1'));
      fakeLookup.store.addRequest(_seedRequest(id: 'r-2'));
      fakeLookup.store.addRequest(_seedRequest(id: 'r-3'));

      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('lookup.request.list.completed', {'count': 3}),
        ),
      );
    });

    test('propagates Failure when lookup.getLookupRequests fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'LOOKUP_UNAVAILABLE',
        message: 'upstream down',
        http: 502,
      );
      final failing = _FailingLookup(error);
      final useCaseFail = GetLookupRequestsUseCase(lookup: failing);

      final result = await useCaseFail.execute(_intent, obs);

      expect(
        result,
        isA<Failure<StandardResponse<List<LookupRequestResponse>>>>(),
      );
    });

    test(
      'emits lookup.request.list.failed with errorCode on backend failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'LOOKUP_UNAVAILABLE',
          message: 'upstream down',
          http: 502,
        );
        final failing = _FailingLookup(error);
        final useCaseFail = GetLookupRequestsUseCase(lookup: failing);

        await useCaseFail.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('lookup.request.list.failed', {
              'errorCode': 'LOOKUP_UNAVAILABLE',
            }),
          ),
        );
      },
    );

    test('breadcrumbs NEVER echo raw justificativa content (PII)', () async {
      fakeLookup.store.addRequest(
        LookupRequestResponse(
          id: 'r-1',
          tableName: 'dominio_diagnostico',
          codigo: 'X',
          descricao: 'Y',
          justificativa: 'Preciso pois minha filha de 5 anos tem Williams',
          status: 'pending',
          createdAt: '2026-04-17T10:00:00Z',
          requestedBy: 'user-42',
        ),
      );

      await useCase.execute(_intent, obs);

      for (final record in obs.breadcrumbs) {
        final dumped = record.data.toString();
        expect(dumped, isNot(contains('filha de 5 anos')));
        expect(dumped, isNot(contains('Williams')));
      }
    });
  });
}
