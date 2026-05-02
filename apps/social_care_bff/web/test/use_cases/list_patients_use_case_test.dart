import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/list_patients_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/list_patients_use_case.dart';

import 'test_observability.dart';

class _FailingRegistry extends FakeRegistryBff {
  _FailingRegistry(this.error);
  final BackendError error;

  @override
  Future<Result<PaginatedList<PatientSummaryResponse>>> fetchPatients({
    String? search,
    String? status,
    String? cursor,
    int? limit,
  }) async => Failure(error);
}

/// Records fetchPatients arguments so tests can assert filters are forwarded.
class _SpyRegistry extends FakeRegistryBff {
  String? capturedSearch;
  String? capturedStatus;
  String? capturedCursor;
  int? capturedLimit;

  @override
  Future<Result<PaginatedList<PatientSummaryResponse>>> fetchPatients({
    String? search,
    String? status,
    String? cursor,
    int? limit,
  }) async {
    capturedSearch = search;
    capturedStatus = status;
    capturedCursor = cursor;
    capturedLimit = limit;
    return super.fetchPatients(
      search: search,
      status: status,
      cursor: cursor,
      limit: limit,
    );
  }
}

void _seed(FakeRegistryBff fake, int count) {
  for (var i = 0; i < count; i++) {
    fake.store.save(
      PatientResponse(patientId: 'pat-$i', personId: 'per-$i'),
      PatientSummaryResponse(
        patientId: 'pat-$i',
        personId: 'per-$i',
        fullName: 'Patient $i',
      ),
    );
  }
}

void main() {
  group('ListPatientsUseCase', () {
    late FakeRegistryBff fakeRegistry;
    late FakePeopleBff fakePeople;
    late ObservabilityContext obs;
    late ListPatientsUseCase useCase;

    setUp(() {
      fakeRegistry = FakeRegistryBff();
      fakePeople = FakePeopleBff();
      obs = ObservabilityContext.noop();
      useCase = ListPatientsUseCase(registry: fakeRegistry, people: fakePeople);
    });

    test('returns Success with an empty list when nothing is stored', () async {
      final result = await useCase.execute(const ListPatientsIntent(), obs);

      expect(result, isA<Success<PaginatedList<PatientSummaryResponse>>>());
      switch (result) {
        case Success(:final value):
          expect(value.data, isEmpty);
        case Failure():
          fail('Expected Success');
      }
    });

    test('returns all seeded patients when no filter is provided', () async {
      _seed(fakeRegistry, 3);

      final result = await useCase.execute(const ListPatientsIntent(), obs);

      switch (result) {
        case Success(:final value):
          expect(value.data, hasLength(3));
        case Failure():
          fail('Expected Success');
      }
    });

    test(
      'forwards search/status/cursor/limit filters to RegistryContract',
      () async {
        final spy = _SpyRegistry();
        final useCaseSpy = ListPatientsUseCase(
          registry: spy,
          people: fakePeople,
        );

        await useCaseSpy.execute(
          const ListPatientsIntent(
            search: 'Ana',
            status: 'admitted',
            cursor: 'c-1',
            limit: 25,
          ),
          obs,
        );

        expect(spy.capturedSearch, equals('Ana'));
        expect(spy.capturedStatus, equals('admitted'));
        expect(spy.capturedCursor, equals('c-1'));
        expect(spy.capturedLimit, equals(25));
      },
    );

    test('emits registry.patient.list.received on dispatch', () async {
      await useCase.execute(
        const ListPatientsIntent(search: 'Ana', cursor: 'c-1'),
        obs,
      );

      expect(
        obs.breadcrumbs,
        contains(hasEvent('registry.patient.list.received')),
      );
    });

    test('emits registry.patient.list.completed with count data', () async {
      _seed(fakeRegistry, 5);

      await useCase.execute(const ListPatientsIntent(), obs);

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('registry.patient.list.completed', {'count': 5}),
        ),
      );
    });

    test('breadcrumbs NEVER carry raw patient full name (PII)', () async {
      fakeRegistry.store.save(
        const PatientResponse(patientId: 'pat-1', personId: 'per-1'),
        const PatientSummaryResponse(
          patientId: 'pat-1',
          personId: 'per-1',
          fullName: 'Ana Beatriz Pereira',
        ),
      );

      await useCase.execute(const ListPatientsIntent(), obs);

      for (final record in obs.breadcrumbs) {
        final dumped = record.data.toString();
        expect(dumped, isNot(contains('Ana Beatriz Pereira')));
      }
    });

    test(
      'propagates Failure when RegistryContract.fetchPatients fails',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'REGISTRY_UNAVAILABLE',
          message: 'service down',
          http: 502,
        );
        final failing = _FailingRegistry(error);
        final useCaseFail = ListPatientsUseCase(
          registry: failing,
          people: fakePeople,
        );

        final result = await useCaseFail.execute(
          const ListPatientsIntent(),
          obs,
        );

        expect(result, isA<Failure<PaginatedList<PatientSummaryResponse>>>());
      },
    );

    test('emits registry.patient.list.failed on backend failure', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'REGISTRY_UNAVAILABLE',
        message: 'service down',
        http: 502,
      );
      final failing = _FailingRegistry(error);
      final useCaseFail = ListPatientsUseCase(
        registry: failing,
        people: fakePeople,
      );

      await useCaseFail.execute(const ListPatientsIntent(), obs);

      expect(
        obs.breadcrumbs,
        contains(hasEvent('registry.patient.list.failed')),
      );
    });
  });
}
