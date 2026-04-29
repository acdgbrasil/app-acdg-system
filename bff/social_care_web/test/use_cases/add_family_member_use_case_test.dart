import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/add_family_member_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/add_family_member_use_case.dart';

import 'test_observability.dart';

/// Wave 0 RED for the REWRITTEN [AddFamilyMemberUseCase].
///
/// Saga composed across [PeopleContract] + [RegistryContract]:
///
/// 1. `registry.family.add.received` — `patientId` + `hasCpf` + `hasPersonId`
///    (NO raw CPF, NO full name).
/// 2. If CPF is present AND `memberPersonId` is empty:
///    - `registry.family.add.people_context.reference_start`
///    - `_people.registerPerson(RegisterPersonRequest(...))`
///    - On [Failure]: emit `registry.family.add.failed` with `errorCode`
///      and SHORT-CIRCUIT — `registry.addFamilyMember` MUST NOT be called.
///    - On [Success]: capture the canonical personId returned by People.
/// 3. `registry.family.add.social_care.family_add_start`
/// 4. `_registry.addFamilyMember(patientId, requestWithResolvedPersonId,
///    cpf: cpf)`.
/// 5. `registry.family.add.completed` with `patientId` + `memberPersonId`
///    (the resolved one). On [Failure] emit `.failed` with `errorCode`.
///
/// Compensation is deliberately not implemented (People Context ends up
/// with an orphan person record if step 4 fails after step 2 succeeded) —
/// documented here to avoid surprise for Wave 1 reviewers.

/// [RegistryContract] fake that forces [addFamilyMember] to fail. Also spies
/// on the call count so we can assert the short-circuit invariant from the
/// People Context failure path.
class _FailingRegistry extends FakeRegistryBff {
  _FailingRegistry(this.error);
  final BackendError error;
  int addFamilyMemberCallCount = 0;
  AddFamilyMemberRequest? lastRequest;
  String? lastCpfPassed;

  @override
  Future<Result<void>> addFamilyMember(
    String patientId,
    AddFamilyMemberRequest request, {
    String? cpf,
  }) async {
    addFamilyMemberCallCount++;
    lastRequest = request;
    lastCpfPassed = cpf;
    return Failure(error);
  }
}

/// Spy variant that succeeds but records what it received — used to pin the
/// invariant that the resolved `memberPersonId` is forwarded to the Registry.
class _SpyRegistry extends FakeRegistryBff {
  int addFamilyMemberCallCount = 0;
  AddFamilyMemberRequest? lastRequest;
  String? lastCpfPassed;

  @override
  Future<Result<void>> addFamilyMember(
    String patientId,
    AddFamilyMemberRequest request, {
    String? cpf,
  }) async {
    addFamilyMemberCallCount++;
    lastRequest = request;
    lastCpfPassed = cpf;
    return const Success(null);
  }
}

/// Spy variant of the People fake — tracks how many times `registerPerson`
/// was invoked so the "no CPF => People NOT called" branch can be pinned.
class _SpyPeople extends FakePeopleBff {
  int registerPersonCallCount = 0;
  RegisterPersonRequest? lastRequest;

  @override
  Future<Result<StandardIdResponse>> registerPerson(
    RegisterPersonRequest request,
  ) async {
    registerPersonCallCount++;
    lastRequest = request;
    return super.registerPerson(request);
  }
}

/// [PeopleContract] fake that forces [registerPerson] to fail.
class _FailingPeople extends FakePeopleBff {
  _FailingPeople(this.error);
  final BackendError error;

  @override
  Future<Result<StandardIdResponse>> registerPerson(
    RegisterPersonRequest request,
  ) async => Failure(error);
}

/// Intent with CPF + fullName but no memberPersonId — drives the composed
/// saga (People resolves → Registry gets the canonical id).
AddFamilyMemberIntent _intentWithCpf() {
  return const AddFamilyMemberIntent(
    patientId: 'pat-1',
    cpf: '11144477735',
    fullName: 'Ana Silva',
    request: AddFamilyMemberRequest(
      memberPersonId: '', // Wave 1 resolves via People Context.
      relationship: 'CHILD',
      isResiding: true,
      isCaregiver: false,
      hasDisability: false,
      birthDate: '2018-05-10',
      prRelationshipId: 'rel-child',
    ),
  );
}

/// Intent with a pre-supplied memberPersonId — solo path, People is NOT
/// contacted.
AddFamilyMemberIntent _intentSolo() {
  return const AddFamilyMemberIntent(
    patientId: 'pat-1',
    request: AddFamilyMemberRequest(
      memberPersonId: 'per-42',
      relationship: 'SIBLING',
      isResiding: false,
      isCaregiver: false,
      hasDisability: false,
      birthDate: '2010-01-01',
      prRelationshipId: 'rel-sibling',
    ),
  );
}

void main() {
  group('AddFamilyMemberUseCase', () {
    late FakeRegistryBff fakeRegistry;
    late FakePeopleBff fakePeople;
    late ObservabilityContext obs;
    late AddFamilyMemberUseCase useCase;

    setUp(() {
      fakeRegistry = FakeRegistryBff();
      fakePeople = FakePeopleBff();
      obs = ObservabilityContext.noop();
      useCase = AddFamilyMemberUseCase(
        registry: fakeRegistry,
        people: fakePeople,
      );
    });

    group('happy path — solo (no CPF, memberPersonId present)', () {
      test('returns Success', () async {
        final result = await useCase.execute(_intentSolo(), obs);

        expect(result, isA<Success<StandardResponse<void>>>());
      });

      test('does NOT call People Context when no CPF is supplied', () async {
        final spyPeople = _SpyPeople();
        final useCaseSpy = AddFamilyMemberUseCase(
          registry: fakeRegistry,
          people: spyPeople,
        );

        await useCaseSpy.execute(_intentSolo(), obs);

        expect(
          spyPeople.registerPersonCallCount,
          equals(0),
          reason: 'Solo intent must not hit People Context',
        );
      });

      test(
        'calls Registry.addFamilyMember with the supplied memberPersonId',
        () async {
          final spyRegistry = _SpyRegistry();
          final useCaseSpy = AddFamilyMemberUseCase(
            registry: spyRegistry,
            people: fakePeople,
          );

          await useCaseSpy.execute(_intentSolo(), obs);

          expect(spyRegistry.addFamilyMemberCallCount, equals(1));
          expect(spyRegistry.lastRequest?.memberPersonId, equals('per-42'));
        },
      );
    });

    group('happy path — composed (CPF present, People → Registry)', () {
      test('returns Success', () async {
        final result = await useCase.execute(_intentWithCpf(), obs);

        expect(result, isA<Success<StandardResponse<void>>>());
      });

      test('registers the person in People Context FIRST', () async {
        final spyPeople = _SpyPeople();
        final useCaseSpy = AddFamilyMemberUseCase(
          registry: fakeRegistry,
          people: spyPeople,
        );

        await useCaseSpy.execute(_intentWithCpf(), obs);

        expect(spyPeople.registerPersonCallCount, equals(1));
        expect(spyPeople.lastRequest?.cpf, equals('11144477735'));
        expect(spyPeople.lastRequest?.fullName, equals('Ana Silva'));
      });

      test(
        'forwards the People-resolved memberPersonId to Registry (not empty)',
        () async {
          final spyRegistry = _SpyRegistry();
          final useCaseSpy = AddFamilyMemberUseCase(
            registry: spyRegistry,
            people: fakePeople,
          );

          await useCaseSpy.execute(_intentWithCpf(), obs);

          expect(spyRegistry.lastRequest?.memberPersonId, isNotEmpty);
        },
      );

      test('forwards the CPF as a side-channel arg to Registry', () async {
        final spyRegistry = _SpyRegistry();
        final useCaseSpy = AddFamilyMemberUseCase(
          registry: spyRegistry,
          people: fakePeople,
        );

        await useCaseSpy.execute(_intentWithCpf(), obs);

        expect(spyRegistry.lastCpfPassed, equals('11144477735'));
      });
    });

    group('observability canon (A07+A08 breadcrumbs)', () {
      test(
        'emits registry.family.add.received with patientId + hasCpf + hasPersonId',
        () async {
          await useCase.execute(_intentWithCpf(), obs);

          expect(
            obs.breadcrumbs,
            contains(
              hasEventWithData('registry.family.add.received', {
                'patientId': 'pat-1',
                'hasCpf': true,
                'hasPersonId': false,
              }),
            ),
          );
        },
      );

      test(
        'emits registry.family.add.received with hasCpf=false for solo path',
        () async {
          await useCase.execute(_intentSolo(), obs);

          expect(
            obs.breadcrumbs,
            contains(
              hasEventWithData('registry.family.add.received', {
                'patientId': 'pat-1',
                'hasCpf': false,
                'hasPersonId': true,
              }),
            ),
          );
        },
      );

      test('emits registry.family.add.people_context.reference_start when CPF '
          'is present', () async {
        await useCase.execute(_intentWithCpf(), obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEvent('registry.family.add.people_context.reference_start'),
          ),
        );
      });

      test('emits registry.family.add.social_care.family_add_start', () async {
        await useCase.execute(_intentWithCpf(), obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEvent('registry.family.add.social_care.family_add_start'),
          ),
        );
      });

      test(
        'emits registry.family.add.completed with patientId on success',
        () async {
          await useCase.execute(_intentWithCpf(), obs);

          expect(
            obs.breadcrumbs,
            contains(
              hasEventWithData('registry.family.add.completed', {
                'patientId': 'pat-1',
              }),
            ),
          );
        },
      );

      test('breadcrumbs NEVER carry raw CPF', () async {
        await useCase.execute(_intentWithCpf(), obs);

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString();
          expect(
            dumped,
            isNot(contains('11144477735')),
            reason: 'Raw CPF must be masked in breadcrumbs (A08 PII canon)',
          );
        }
      });

      test('breadcrumbs NEVER carry raw full name', () async {
        await useCase.execute(_intentWithCpf(), obs);

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString();
          expect(dumped, isNot(contains('Ana Silva')));
        }
      });
    });

    group('failure paths', () {
      test(
        'propagates Failure when People Context registration fails',
        () async {
          const error = BackendError(
            id: 'err-1',
            code: 'PEOPLE_UNAVAILABLE',
            message: 'people context down',
            http: 502,
          );
          final failingPeople = _FailingPeople(error);
          final useCaseFail = AddFamilyMemberUseCase(
            registry: fakeRegistry,
            people: failingPeople,
          );

          final result = await useCaseFail.execute(_intentWithCpf(), obs);

          expect(result, isA<Failure<StandardResponse<void>>>());
        },
      );

      test(
        'does NOT call addFamilyMember when People registerPerson fails',
        () async {
          const error = BackendError(
            id: 'err-1',
            code: 'PEOPLE_UNAVAILABLE',
            message: 'people context down',
            http: 502,
          );
          final failingPeople = _FailingPeople(error);
          final failingRegistry = _FailingRegistry(
            const BackendError(
              id: 'never-called',
              code: 'SHOULD_NOT_HIT',
              message: 'registry was called even though people failed',
              http: 500,
            ),
          );
          final useCaseFail = AddFamilyMemberUseCase(
            registry: failingRegistry,
            people: failingPeople,
          );

          await useCaseFail.execute(_intentWithCpf(), obs);

          expect(
            failingRegistry.addFamilyMemberCallCount,
            equals(0),
            reason:
                'Short-circuit invariant: no Registry call after People failure',
          );
        },
      );

      test(
        'emits registry.family.add.failed with errorCode on People failure',
        () async {
          const error = BackendError(
            id: 'err-1',
            code: 'PEOPLE_UNAVAILABLE',
            message: 'people context down',
            http: 502,
          );
          final failingPeople = _FailingPeople(error);
          final useCaseFail = AddFamilyMemberUseCase(
            registry: fakeRegistry,
            people: failingPeople,
          );

          await useCaseFail.execute(_intentWithCpf(), obs);

          expect(
            obs.breadcrumbs,
            contains(
              hasEventWithData('registry.family.add.failed', {
                'errorCode': 'PEOPLE_UNAVAILABLE',
              }),
            ),
          );
        },
      );

      test('propagates Failure when Registry.addFamilyMember fails', () async {
        const error = BackendError(
          id: 'err-2',
          code: 'RELATIONSHIP_INVALID',
          message: 'bad relationship',
          http: 409,
        );
        final failingRegistry = _FailingRegistry(error);
        final useCaseFail = AddFamilyMemberUseCase(
          registry: failingRegistry,
          people: fakePeople,
        );

        final result = await useCaseFail.execute(_intentSolo(), obs);

        expect(result, isA<Failure<StandardResponse<void>>>());
        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            expect(error, isA<BackendError>());
            expect(
              (error as BackendError).code,
              equals('RELATIONSHIP_INVALID'),
            );
        }
      });

      test(
        'emits registry.family.add.failed with errorCode on Registry failure',
        () async {
          const error = BackendError(
            id: 'err-2',
            code: 'RELATIONSHIP_INVALID',
            message: 'bad relationship',
            http: 409,
          );
          final failingRegistry = _FailingRegistry(error);
          final useCaseFail = AddFamilyMemberUseCase(
            registry: failingRegistry,
            people: fakePeople,
          );

          await useCaseFail.execute(_intentSolo(), obs);

          expect(
            obs.breadcrumbs,
            contains(
              hasEventWithData('registry.family.add.failed', {
                'errorCode': 'RELATIONSHIP_INVALID',
              }),
            ),
          );
        },
      );
    });
  });
}
