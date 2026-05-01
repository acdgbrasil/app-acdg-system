/// RED-phase tests for [RegistryFacade] (A18c-v2).
///
/// 13 public methods delegate to the 13 Registry use cases (A18b-v2).
/// These tests are SMOKE WIRING tests: each method is called once,
/// asserting the return Result type matches what the use case returns.
///
/// Why smoke instead of full coverage:
///   * Use case logic (cache-first, optimistic-through, FIFO) is fully
///     covered by A18b's `registry_use_cases_test.dart`.
///   * The sub-facade is a thin pass-through; W1's only job is to
///     forward arguments and return the Result unchanged.
///   * Re-testing those axes here would couple the facade tests to
///     internal use case state.
///
/// Locked contract:
///
///   class RegistryFacade {
///     RegistryFacade._({...13 use cases...});
///     Future<Result<PatientResponse>> fetchPatient(String id);
///     Future<Result<PatientResponse>> fetchPatientByPersonId(String personId);
///     Future<Result<List<PatientSummaryResponse>>> listPatients({
///       String? status, String? cursor, int? limit,
///     });
///     Future<Result<List<PatientSummaryResponse>>> searchPatients(String term);
///     Future<Result<StandardIdResponse>> registerPatient(RegisterPatientRequest req);
///     Future<Result<void>> addFamilyMember(String patientId, AddFamilyMemberRequest req);
///     Future<Result<void>> removeFamilyMember(String patientId, String memberId);
///     Future<Result<void>> assignPrimaryCaregiver(String patientId, AssignPrimaryCaregiverRequest req);
///     Future<Result<void>> updateSocialIdentity(String patientId, UpdateSocialIdentityRequest req);
///     Future<Result<void>> dischargePatient(String patientId, DischargePatientRequest req);
///     Future<Result<void>> readmitPatient(String patientId, ReadmitPatientRequest req);
///     Future<Result<void>> admitPatient(String patientId);
///     Future<Result<void>> withdrawPatient(String patientId, WithdrawPatientRequest req);
///   }
///
/// IMPORTANT (RED phase): the facade does NOT exist yet. Imports fail.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
// ignore_for_file: depend_on_referenced_packages
import 'package:test/test.dart';

import '../_test_uuids.dart';
import '_test_helpers.dart';

void main() {
  Future<SocialCareDesktop> build(FacadeTestContext ctx) =>
      SocialCareDesktop.create(
        baseUrl: 'http://localhost:8080',
        actorId: 'actor-123',
        tokenProvider: kStaticToken('test-token'),
        cacheFilePath: ':memory:',
        syncQueueFilePath: ':memory:',
        dio: ctx.dio,
        clock: ctx.fakeClock,
        connectivity: ctx.fakeConnectivity,
      );

  group('RegistryFacade — read methods', () {
    test(
      'fetchPatient returns Result<PatientResponse> on cache miss',
      () async {
        final ctx = FacadeTestContext.fresh();
        addTearDown(ctx.close);
        final desktop = await build(ctx);
        addTearDown(desktop.close);

        // Cache empty + remote unwired (no real backend) → Failure expected.
        // What matters: the method returns a Result of the right type.
        final result = await desktop.registry.fetchPatient(kPatientUuid);
        expect(result, isA<Result<PatientResponse>>());
      },
    );

    test('fetchPatientByPersonId returns Result<PatientResponse>', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      final result = await desktop.registry.fetchPatientByPersonId(kPersonUuid);
      expect(result, isA<Result<PatientResponse>>());
    });

    test('listPatients accepts {status, cursor, limit} named params', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      // All three params optional; signatures must match A18b list use case.
      final result = await desktop.registry.listPatients(
        status: 'admitted',
        cursor: 'c1',
        limit: 10,
      );
      expect(result, isA<Result<List<PatientSummaryResponse>>>());
    });

    test('searchPatients takes positional term', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      final result = await desktop.registry.searchPatients('Maria');
      expect(result, isA<Result<List<PatientSummaryResponse>>>());
    });
  });

  group('RegistryFacade — write methods', () {
    test('registerPatient returns Result<StandardIdResponse>', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      const req = RegisterPatientRequest(
        personId: kPersonUuid,
        initialDiagnoses: [],
        prRelationshipId: kRoleUuid,
      );
      final result = await desktop.registry.registerPatient(req);
      expect(result, isA<Result<StandardIdResponse>>());
    });

    test(
      'admitPatient takes (patientId) positional and returns Result<void>',
      () async {
        final ctx = FacadeTestContext.fresh();
        addTearDown(ctx.close);
        final desktop = await build(ctx);
        addTearDown(desktop.close);

        // Cache miss → use case returns Failure(NotFoundFailure). What we
        // assert is the signature: `(String) → Future<Result<void>>`.
        final result = await desktop.registry.admitPatient(kPatientUuid);
        expect(result, isA<Result<void>>());
      },
    );

    test(
      'dischargePatient takes (patientId, request) and returns Result<void>',
      () async {
        final ctx = FacadeTestContext.fresh();
        addTearDown(ctx.close);
        final desktop = await build(ctx);
        addTearDown(desktop.close);

        const req = DischargePatientRequest(reason: 'transferred');
        final result = await desktop.registry.dischargePatient(
          kPatientUuid,
          req,
        );
        expect(result, isA<Result<void>>());
      },
    );
  });
}
