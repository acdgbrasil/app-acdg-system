/// RED-phase tests for Registry use cases (A18b-v2).
///
/// 13 use cases cover the Patient aggregate lifecycle:
///   Reads (4):
///     * `FetchPatientUseCase`           — by patientId, cache-first.
///     * `FetchPatientByPersonIdUseCase` — by personId (B-Tree index).
///     * `ListPatientsUseCase`           — summaries with status/cursor/limit.
///     * `SearchPatientsUseCase`         — FTS5 over patient_summaries_fts.
///   Writes (9):
///     * `RegisterPatientUseCase`        — special: expectedVersion = 0.
///     * `AddFamilyMemberUseCase`, `RemoveFamilyMemberUseCase`,
///       `AssignPrimaryCaregiverUseCase`, `UpdateSocialIdentityUseCase`,
///       `DischargePatientUseCase`, `ReadmitPatientUseCase`,
///       `AdmitPatientUseCase`, `WithdrawPatientUseCase`.
///
/// ── Locked patterns ──────────────────────────────────────────────────
/// Read use case (Pattern 1):
///   1. Cache hit fresh (cachedAt > now - staleAfter) → return cached.
///   2. Cache hit stale → refresh remote + upsert + return refreshed.
///   3. Cache miss → remote fetch + upsert + return.
///   4. Remote failure on miss → propagate `Failure`.
///
/// Write use case (Pattern 2):
///   1. Happy path: outbox enqueued (1 mutation, expectedVersion = N),
///      cache patched to version N+1, fakeEngine.triggerDrainCount = 1,
///      `Result<void>` Success.
///   2. Cache miss for non-Register write → Failure(NotFoundFailure);
///      outbox empty; engine NOT triggered.
///   3. (Register only) → expectedVersion = 0, cache populated with
///      version = 1, engine triggered.
///   4. Outbox enqueue failure → Failure propagated; cache UNCHANGED;
///      engine NOT triggered. (REGRA #2: optimistic update happens
///      AFTER successful enqueue only.)
///
/// REGRA #2 lock: NO rollback on `failed_dead`. That is the SyncEngine's
/// async concern (A18a-v2 already locked); A18b's write use case
/// returns Success once the mutation is durably enqueued. The optimistic
/// cache stays put; UI surfaces the inconsistency (A18c-v2).
///
/// REGRA #2 lock (concurrent writes): user issues
/// `dischargePatient` then `admitPatient` rapidly. We assert FIFO
/// preservation in the Outbox + monotonic expectedVersion sequence
/// (5, 6) + cache reflects the LAST optimistic update + 2 drain
/// triggers. Race against the real backend is A18a's territory.
///
/// IMPORTANT (RED phase): Use cases under
/// `lib/src/use_cases/registry/...` do NOT exist yet. The `import`
/// lines fail — that is the intended RED signal.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

// ── Use cases (RED — does not exist yet) ──────────────────────────────
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/registry/fetch_patient_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/registry/fetch_patient_by_person_id_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/registry/list_patients_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/registry/search_patients_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/registry/register_patient_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/registry/add_family_member_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/registry/remove_family_member_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/registry/assign_primary_caregiver_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/registry/update_social_identity_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/registry/discharge_patient_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/registry/readmit_patient_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/registry/admit_patient_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/registry/withdraw_patient_use_case.dart';

import '../_test_uuids.dart';
import '_test_helpers.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // Fixtures
  // ─────────────────────────────────────────────────────────────────────

  PatientResponse patientFixture({
    String patientId = kPatientUuid,
    String personId = kPersonUuid,
    int version = 5,
    String status = 'admitted',
  }) =>
      PatientResponse(
        patientId: patientId,
        personId: personId,
        version: version,
        status: status,
        prRelationshipId: kRoleUuid,
      );

  PatientSummaryResponse summaryFixture({
    String patientId = kPatientUuid,
    String personId = kPersonUuid,
    String status = 'admitted',
  }) =>
      PatientSummaryResponse(
        patientId: patientId,
        personId: personId,
        firstName: 'Maria',
        lastName: 'Silva',
        fullName: 'Maria Silva',
        status: status,
      );

  // ═════════════════════════════════════════════════════════════════════
  // READ — FetchPatientUseCase (Pattern 1)
  // ═════════════════════════════════════════════════════════════════════

  group('FetchPatientUseCase (Pattern 1 — read)', () {
    test('cache hit fresh returns cached without calling remote', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final patient = patientFixture();
      await ctx.patientsCache.upsertPatient(patient, version: 5);

      final useCase = FetchPatientUseCase(
        cache: ctx.patientsCache,
        remote: ctx.fakeRegistry,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid);

      expect(result, isA<Success<PatientResponse>>());
      final value = (result as Success<PatientResponse>).value;
      expect(value.patientId, kPatientUuid);
      expect(value.personId, kPersonUuid);
      // Remote was not consulted: store stays empty.
      expect(ctx.fakeRegistry.store.patients, isEmpty);
    });

    test('cache hit stale refreshes from remote', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      // Seed cache, then advance clock past staleAfter (default 5min).
      await ctx.patientsCache.upsertPatient(patientFixture(version: 5),
          version: 5);
      ctx.fakeClock.advance(const Duration(minutes: 10));

      // Seed remote with a newer version.
      ctx.fakeRegistry.store.save(
        patientFixture(version: 6, status: 'discharged'),
        summaryFixture(status: 'discharged'),
      );

      final useCase = FetchPatientUseCase(
        cache: ctx.patientsCache,
        remote: ctx.fakeRegistry,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid);

      expect(result, isA<Success<PatientResponse>>());
      final value = (result as Success<PatientResponse>).value;
      expect(value.status, 'discharged');
      expect(value.version, 6);
    });

    test('cache miss fetches from remote and upserts', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      ctx.fakeRegistry.store.save(
        patientFixture(version: 3),
        summaryFixture(),
      );

      final useCase = FetchPatientUseCase(
        cache: ctx.patientsCache,
        remote: ctx.fakeRegistry,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid);

      expect(result, isA<Success<PatientResponse>>());

      // Cache should now have the patient.
      final cached = await ctx.patientsCache.findById(kPatientUuid);
      expect(cached, isA<Success>());
      // Cached<T> envelope: dto + cachedAt + version.
      final wrapped = (cached as Success).value as Cached<PatientResponse>?;
      expect(wrapped, isNotNull);
      expect(wrapped!.dto.patientId, kPatientUuid);
      expect(wrapped.version, 3);
    });

    test('remote failure on cache miss propagates Failure', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      // Empty remote store → fetchPatient returns Failure.
      final useCase = FetchPatientUseCase(
        cache: ctx.patientsCache,
        remote: ctx.fakeRegistry,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid);

      expect(result, isA<Failure<PatientResponse>>());
    });

    test('staleAfter is configurable per use case', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patientFixture(), version: 5);
      // Advance only 30s — would be stale under 10s threshold.
      ctx.fakeClock.advance(const Duration(seconds: 30));

      final useCase = FetchPatientUseCase(
        cache: ctx.patientsCache,
        remote: ctx.fakeRegistry,
        clock: ctx.fakeClock,
        staleAfter: const Duration(seconds: 10),
      );

      // Seed remote with different status so we can detect a refresh.
      ctx.fakeRegistry.store.save(
        patientFixture(version: 6, status: 'discharged'),
        summaryFixture(status: 'discharged'),
      );

      final result = await useCase(kPatientUuid);
      expect((result as Success<PatientResponse>).value.status, 'discharged');
    });
  });

  // ═════════════════════════════════════════════════════════════════════
  // READ — FetchPatientByPersonIdUseCase
  // ═════════════════════════════════════════════════════════════════════

  group('FetchPatientByPersonIdUseCase (Pattern 1)', () {
    test('cache hit fresh by personId', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patientFixture(), version: 5);

      final useCase = FetchPatientByPersonIdUseCase(
        cache: ctx.patientsCache,
        remote: ctx.fakeRegistry,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPersonUuid);
      expect(result, isA<Success<PatientResponse>>());
      expect(
          (result as Success<PatientResponse>).value.personId, kPersonUuid);
    });

    test('cache miss falls back to remote.fetchPatientByPersonId', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      ctx.fakeRegistry.store
          .save(patientFixture(version: 2), summaryFixture());

      final useCase = FetchPatientByPersonIdUseCase(
        cache: ctx.patientsCache,
        remote: ctx.fakeRegistry,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPersonUuid);
      expect(result, isA<Success<PatientResponse>>());
    });

    test('remote failure on miss propagates', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = FetchPatientByPersonIdUseCase(
        cache: ctx.patientsCache,
        remote: ctx.fakeRegistry,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPersonUuid);
      expect(result, isA<Failure<PatientResponse>>());
    });
  });

  // ═════════════════════════════════════════════════════════════════════
  // READ — ListPatientsUseCase
  // ═════════════════════════════════════════════════════════════════════

  group('ListPatientsUseCase (Pattern 1)', () {
    test('cache hit fresh returns summaries', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertSummary(summaryFixture(), version: 1);

      final useCase = ListPatientsUseCase(
        cache: ctx.patientsCache,
        remote: ctx.fakeRegistry,
        clock: ctx.fakeClock,
      );

      final result = await useCase();
      expect(result, isA<Success<List<PatientSummaryResponse>>>());
      expect(
          (result as Success<List<PatientSummaryResponse>>).value, hasLength(1));
    });

    test('cache miss fans out to remote and upserts', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      ctx.fakeRegistry.store
          .save(patientFixture(version: 1), summaryFixture());

      final useCase = ListPatientsUseCase(
        cache: ctx.patientsCache,
        remote: ctx.fakeRegistry,
        clock: ctx.fakeClock,
      );

      final result = await useCase();
      expect(result, isA<Success<List<PatientSummaryResponse>>>());
      expect((result as Success<List<PatientSummaryResponse>>).value,
          hasLength(1));
    });

    test('respects status filter', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertSummary(summaryFixture(status: 'admitted'),
          version: 1);
      await ctx.patientsCache.upsertSummary(
          summaryFixture(
              patientId: kPatientUuidAlt,
              personId: kPersonUuidAlt,
              status: 'discharged'),
          version: 1);

      final useCase = ListPatientsUseCase(
        cache: ctx.patientsCache,
        remote: ctx.fakeRegistry,
        clock: ctx.fakeClock,
      );

      final result = await useCase(status: 'discharged');
      final summaries =
          (result as Success<List<PatientSummaryResponse>>).value;
      expect(summaries, hasLength(1));
      expect(summaries.single.status, 'discharged');
    });
  });

  // ═════════════════════════════════════════════════════════════════════
  // READ — SearchPatientsUseCase
  // ═════════════════════════════════════════════════════════════════════

  group('SearchPatientsUseCase (Pattern 1, FTS5)', () {
    test('cache hit returns FTS5 matches', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertSummary(summaryFixture(), version: 1);

      final useCase = SearchPatientsUseCase(
        cache: ctx.patientsCache,
        remote: ctx.fakeRegistry,
        clock: ctx.fakeClock,
      );

      final result = await useCase('Maria');
      expect(result, isA<Success<List<PatientSummaryResponse>>>());
      expect((result as Success<List<PatientSummaryResponse>>).value,
          hasLength(1));
    });

    test('empty cache → falls back to remote search', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      ctx.fakeRegistry.store
          .save(patientFixture(version: 1), summaryFixture());

      final useCase = SearchPatientsUseCase(
        cache: ctx.patientsCache,
        remote: ctx.fakeRegistry,
        clock: ctx.fakeClock,
      );

      final result = await useCase('Maria');
      expect(result, isA<Success<List<PatientSummaryResponse>>>());
    });
  });

  // ═════════════════════════════════════════════════════════════════════
  // WRITE — RegisterPatientUseCase (Pattern 2 — special: expectedVersion 0)
  // ═════════════════════════════════════════════════════════════════════

  group('RegisterPatientUseCase (Pattern 2 — register special-case)', () {
    RegisterPatientRequest req() => const RegisterPatientRequest(
          personId: kPersonUuid,
          initialDiagnoses: [],
          prRelationshipId: kRoleUuid,
        );

    test('happy path: enqueues mutation with expectedVersion 0 and triggers drain',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = RegisterPatientUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(req());
      expect(result, isA<Success<StandardIdResponse>>());

      // 1) Outbox has exactly one mutation.
      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entries = (pending as Success<List<OutboxEntry>>).value;
      expect(entries, hasLength(1));
      expect(entries.first.mutationType, 'register_patient');
      expect(entries.first.expectedVersion, 0);

      // 2) Engine triggered.
      expect(ctx.fakeEngine.triggerDrainCount, 1);
    });

    test('outbox enqueue failure propagates and engine NOT triggered',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      // Closing the SyncDatabase forces every Outbox call to Failure.
      await ctx.syncDb.close();

      final useCase = RegisterPatientUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(req());
      expect(result, isA<Failure<StandardIdResponse>>());
      expect(ctx.fakeEngine.triggerDrainCount, 0);
    });
  });

  // ═════════════════════════════════════════════════════════════════════
  // WRITE — DischargePatientUseCase (canonical Pattern 2)
  // ═════════════════════════════════════════════════════════════════════

  group('DischargePatientUseCase (Pattern 2 — write)', () {
    const dischargeReq = DischargePatientRequest(reason: 'transferred');

    test(
        'happy path: enqueues mutation, optimistic cache update, triggers drain',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      // Seed cache with version 5 patient.
      await ctx.patientsCache.upsertPatient(patientFixture(version: 5),
          version: 5);

      final useCase = DischargePatientUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, dischargeReq);
      expect(result, isA<Success<void>>());

      // 1) Outbox: 1 pending mutation, expectedVersion = 5.
      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entries = (pending as Success<List<OutboxEntry>>).value;
      expect(entries, hasLength(1));
      expect(entries.first.aggregateId, kPatientUuid);
      expect(entries.first.mutationType, 'discharge_patient');
      expect(entries.first.expectedVersion, 5);

      // 2) Cache reflects optimistic update — version bumped to 6.
      final cached = (await ctx.patientsCache.findById(kPatientUuid)
              as Success<Cached<PatientResponse>?>)
          .value!;
      expect(cached.version, 6);

      // 3) Engine triggered.
      expect(ctx.fakeEngine.triggerDrainCount, 1);
    });

    test('cache miss → Failure(NotFoundFailure); outbox empty; engine untouched',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = DischargePatientUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, dischargeReq);
      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<NotFoundFailure>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      expect((pending as Success<List<OutboxEntry>>).value, isEmpty);
      expect(ctx.fakeEngine.triggerDrainCount, 0);
    });

    test('outbox enqueue failure → cache UNCHANGED; engine NOT triggered',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patientFixture(version: 5),
          version: 5);

      // Force outbox failure.
      await ctx.syncDb.close();

      final useCase = DischargePatientUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, dischargeReq);
      expect(result, isA<Failure<void>>());

      // Cache version stayed at 5.
      final cached = (await ctx.patientsCache.findById(kPatientUuid)
              as Success<Cached<PatientResponse>?>)
          .value!;
      expect(cached.version, 5);
      expect(ctx.fakeEngine.triggerDrainCount, 0);
    });
  });

  // ═════════════════════════════════════════════════════════════════════
  // WRITE — Other Registry write use cases (smoke + Pattern-2 invariants)
  // ═════════════════════════════════════════════════════════════════════

  group('AddFamilyMemberUseCase (Pattern 2)', () {
    const addReq = AddFamilyMemberRequest(
      memberPersonId: kPersonUuidAlt,
      relationship: 'mother',
      isResiding: true,
      isCaregiver: true,
      hasDisability: false,
      birthDate: '1990-01-01',
      prRelationshipId: kRoleUuid,
    );

    test('happy path enqueues add_family_member mutation', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patientFixture(version: 2),
          version: 2);

      final useCase = AddFamilyMemberUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, addReq);
      expect(result, isA<Success<void>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entries = (pending as Success<List<OutboxEntry>>).value;
      expect(entries.single.mutationType, 'add_family_member');
      expect(entries.single.expectedVersion, 2);
      expect(ctx.fakeEngine.triggerDrainCount, 1);
    });

    test('cache miss → Failure(NotFoundFailure)', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = AddFamilyMemberUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, addReq);
      expect((result as Failure<void>).error, isA<NotFoundFailure>());
    });
  });

  group('RemoveFamilyMemberUseCase (Pattern 2)', () {
    test('happy path enqueues remove_family_member with memberId payload',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patientFixture(version: 1),
          version: 1);

      final useCase = RemoveFamilyMemberUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, kFamilyMemberUuid);
      expect(result, isA<Success<void>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entries = (pending as Success<List<OutboxEntry>>).value;
      expect(entries.single.mutationType, 'remove_family_member');
      expect(entries.single.payload['memberId'], kFamilyMemberUuid);
    });
  });

  group('AssignPrimaryCaregiverUseCase (Pattern 2)', () {
    test('happy path enqueues assign_primary_caregiver', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patientFixture(version: 3),
          version: 3);

      final useCase = AssignPrimaryCaregiverUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      const req = AssignPrimaryCaregiverRequest(memberPersonId: kPersonUuidAlt);
      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Success<void>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      expect(
          (pending as Success<List<OutboxEntry>>).value.single.mutationType,
          'assign_primary_caregiver');
      expect(ctx.fakeEngine.triggerDrainCount, 1);
    });
  });

  group('UpdateSocialIdentityUseCase (Pattern 2)', () {
    test('happy path enqueues update_social_identity', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patientFixture(version: 1),
          version: 1);

      final useCase = UpdateSocialIdentityUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      const req = UpdateSocialIdentityRequest(typeId: kLookupItemUuid);
      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Success<void>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      expect(
          (pending as Success<List<OutboxEntry>>).value.single.mutationType,
          'update_social_identity');
    });
  });

  group('ReadmitPatientUseCase (Pattern 2)', () {
    test('happy path enqueues readmit_patient', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patientFixture(version: 4),
          version: 4);

      final useCase = ReadmitPatientUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      const req = ReadmitPatientRequest();
      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Success<void>>());
      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      expect(
          (pending as Success<List<OutboxEntry>>).value.single.mutationType,
          'readmit_patient');
    });
  });

  group('AdmitPatientUseCase (Pattern 2 — body-less)', () {
    test('happy path enqueues admit_patient with empty payload', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patientFixture(version: 0),
          version: 0);

      final useCase = AdmitPatientUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid);
      expect(result, isA<Success<void>>());
      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entry =
          (pending as Success<List<OutboxEntry>>).value.single;
      expect(entry.mutationType, 'admit_patient');
      expect(entry.payload, isEmpty);
    });
  });

  group('WithdrawPatientUseCase (Pattern 2)', () {
    test('happy path enqueues withdraw_patient', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patientFixture(version: 2),
          version: 2);

      final useCase = WithdrawPatientUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      const req = WithdrawPatientRequest(reason: 'left_program');
      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Success<void>>());
      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      expect(
          (pending as Success<List<OutboxEntry>>).value.single.mutationType,
          'withdraw_patient');
    });
  });

  // ═════════════════════════════════════════════════════════════════════
  // REGRA #2 #3 — Concurrent writes preserve FIFO + monotonic version
  // ═════════════════════════════════════════════════════════════════════

  group('Concurrent writes preserve FIFO + monotonic expectedVersion', () {
    test(
        'discharge then admit on same patient: 2 mutations, versions 5+6, 2 drain triggers',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patientFixture(version: 5),
          version: 5);

      final discharge = DischargePatientUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );
      final admit = AdmitPatientUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      // Sequential to make ordering deterministic.
      await discharge(kPatientUuid,
          const DischargePatientRequest(reason: 'transferred'));
      // Bump fake clock so the second mutation has a strictly later
      // createdAt — outbox ordering is FIFO by createdAt ASC.
      ctx.fakeClock.advance(const Duration(milliseconds: 10));
      await admit(kPatientUuid);

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entries = (pending as Success<List<OutboxEntry>>).value;
      expect(entries, hasLength(2));
      expect(entries[0].mutationType, 'discharge_patient');
      expect(entries[0].expectedVersion, 5);
      expect(entries[1].mutationType, 'admit_patient');
      expect(entries[1].expectedVersion, 6);

      // Cache shows the LAST optimistic update (admitted, version 7).
      final cached = (await ctx.patientsCache.findById(kPatientUuid)
              as Success<Cached<PatientResponse>?>)
          .value!;
      expect(cached.version, 7);

      // Both writes triggered drain — single-flight is engine's concern.
      expect(ctx.fakeEngine.triggerDrainCount, 2);
    });
  });
}
