import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/create_lookup_request_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/create_lookup_request_use_case.dart';

import 'test_observability.dart';

/// Forces every call to [LookupContract.createLookupRequest] to fail with the
/// configured [BackendError]. Used to validate the failure-path breadcrumb.
class _FailingLookup extends FakeLookupBff {
  _FailingLookup(this.error);
  final BackendError error;

  @override
  Future<Result<StandardIdResponse>> createLookupRequest(
    CreateLookupRequestRequest request,
  ) async => Failure(error);
}

const _request = CreateLookupRequestRequest(
  tableName: 'dominio_diagnostico',
  codigo: 'WILLIAMS',
  descricao: 'Sindrome de Williams',
  justificativa: 'Preciso pois minha filha de 5 anos tem Williams',
);

const _intent = CreateLookupRequestIntent(request: _request);

void main() {
  group('CreateLookupRequestUseCase', () {
    late FakeLookupBff fakeLookup;
    late ObservabilityContext obs;
    late CreateLookupRequestUseCase useCase;

    setUp(() {
      fakeLookup = FakeLookupBff();
      obs = ObservabilityContext.noop();
      useCase = CreateLookupRequestUseCase(lookup: fakeLookup);
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

    test('persists request on the fake store (side-effect)', () async {
      await useCase.execute(_intent, obs);

      expect(fakeLookup.store.requests, hasLength(1));
      expect(
        fakeLookup.store.requests.first.tableName,
        equals('dominio_diagnostico'),
      );
    });

    test('emits lookup.request.create.received with tableName only', () async {
      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('lookup.request.create.received', {
            'tableName': 'dominio_diagnostico',
          }),
        ),
      );
    });

    test('emits lookup.request.create.completed on success', () async {
      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(hasEvent('lookup.request.create.completed')),
      );
    });

    test('.completed breadcrumb carries requestId (non-PII UUID)', () async {
      final result = await useCase.execute(_intent, obs);

      final expectedId = switch (result) {
        Success(:final value) => value.data.id,
        Failure() => fail('Expected Success'),
      };

      final completed = obs.breadcrumbs.firstWhere(
        (b) => b.event == 'lookup.request.create.completed',
      );
      expect(completed.data['requestId'], equals(expectedId));
    });

    test('propagates Failure when lookup.createLookupRequest fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'DUPLICATE_REQUEST',
        message: 'a request for this code already exists',
        http: 409,
      );
      final failing = _FailingLookup(error);
      final useCaseFail = CreateLookupRequestUseCase(lookup: failing);

      final result = await useCaseFail.execute(_intent, obs);

      expect(result, isA<Failure<StandardIdResponse>>());
    });

    test(
      'emits lookup.request.create.failed with errorCode on backend failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'DUPLICATE_REQUEST',
          message: 'a request for this code already exists',
          http: 409,
        );
        final failing = _FailingLookup(error);
        final useCaseFail = CreateLookupRequestUseCase(lookup: failing);

        await useCaseFail.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('lookup.request.create.failed', {
              'errorCode': 'DUPLICATE_REQUEST',
            }),
          ),
        );
      },
    );

    test(
      'breadcrumbs NEVER echo raw justificativa content (PII — CRITICAL)',
      () async {
        await useCase.execute(_intent, obs);

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString();
          expect(
            dumped,
            isNot(contains('filha de 5 anos')),
            reason: 'justificativa must not surface in breadcrumb data',
          );
          expect(
            dumped,
            isNot(contains('Preciso pois')),
            reason: 'justificativa must not surface in breadcrumb data',
          );
          expect(
            dumped,
            isNot(contains('Williams')),
            reason: 'descricao must not surface in breadcrumb data',
          );
        }
      },
    );

    test(
      'breadcrumbs NEVER echo raw codigo / descricao (domain payload)',
      () async {
        await useCase.execute(_intent, obs);

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString();
          expect(dumped, isNot(contains('WILLIAMS')));
          expect(dumped, isNot(contains('Sindrome de Williams')));
        }
      },
    );
  });
}
