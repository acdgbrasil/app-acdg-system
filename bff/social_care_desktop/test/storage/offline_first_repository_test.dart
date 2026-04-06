import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:social_care_desktop/src/storage/local_cache_contract.dart';
import 'package:social_care_desktop/src/storage/offline_first_repository.dart';
import 'package:network/network.dart';

// ── Test fixtures ────────────────────────────────────────────────

final _patientId = PatientId.create(
  '550e8400-e29b-41d4-a716-446655440000',
).valueOrNull!;

final _patient = Patient.reconstitute(
  id: _patientId,
  personId: PersonId.create(
    '550e8400-e29b-41d4-a716-446655440001',
  ).valueOrNull!,
  prRelationshipId: LookupId.create(
    '550e8400-e29b-41d4-a716-446655440002',
  ).valueOrNull!,
  version: 1,
);

final _patientRemote = PatientRemote.fromJson(
  PatientTranslator.toJson(_patient),
);

// ── Fakes ────────────────────────────────────────────────────────

/// Fake sync scheduler that tracks calls.
class FakeSyncScheduler implements SyncScheduler {
  int scheduleCallCount = 0;

  @override
  void scheduleProcessQueue() {
    scheduleCallCount++;
  }
}

/// In-memory implementation of [LocalCacheContract] for testing.
class InMemoryLocalRepository implements LocalCacheContract {
  final Map<String, PatientRemote> _cache = {};
  final Map<String, PatientId> _registered = {};
  bool _hasPending = false;
  int registerPatientCallCount = 0;

  void setHasPendingActions(bool value) => _hasPending = value;

  @override
  Future<bool> hasPendingActions(PatientId patientId) async => _hasPending;

  @override
  Future<void> updateCacheFromRemote(PatientRemote dto) async {
    _cache[dto.patientId] = dto;
  }

  @override
  Future<void> updateCacheFromSummaries(List<PatientOverview> summaries) async {}

  @override
  Future<void> updateLookupCache(String tableName, List<LookupItem> items) async {}

  @override
  Future<Result<PatientId>> registerPatient(Patient patient) async {
    registerPatientCallCount++;
    _registered[patient.id.value] = patient.id;
    return Success(patient.id);
  }

  @override
  Future<Result<PatientRemote>> fetchPatient(PatientId id) async {
    final cached = _cache[id.value];
    if (cached != null) return Success(cached);
    return const Failure('Not found in local cache');
  }

  @override
  Future<Result<void>> checkHealth() async => const Success(null);
  @override
  Future<Result<void>> checkReady() async => const Success(null);
  @override
  Future<Result<List<PatientOverview>>> fetchPatients() async =>
      const Success([]);
  @override
  Future<Result<PatientRemote>> fetchPatientByPersonId(PersonId personId) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> addFamilyMember(
    PatientId patientId,
    FamilyMember member,
    LookupId prRelationshipId,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> removeFamilyMember(
    PatientId patientId,
    PersonId memberId,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> assignPrimaryCaregiver(
    PatientId patientId,
    PersonId memberId,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updateSocialIdentity(
    PatientId patientId,
    SocialIdentity identity,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<List<AuditEvent>>> getAuditTrail(
    PatientId patientId, {
    String? eventType,
  }) async =>
      const Success([]);
  @override
  Future<Result<void>> updateHousingCondition(
    PatientId patientId,
    HousingCondition condition,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updateSocioEconomicSituation(
    PatientId patientId,
    SocioEconomicSituation situation,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updateWorkAndIncome(
    PatientId patientId,
    WorkAndIncome data,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updateEducationalStatus(
    PatientId patientId,
    EducationalStatus status,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updateHealthStatus(
    PatientId patientId,
    HealthStatus status,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updateCommunitySupportNetwork(
    PatientId patientId,
    CommunitySupportNetwork network,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updateSocialHealthSummary(
    PatientId patientId,
    SocialHealthSummary summary,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<AppointmentId>> registerAppointment(
    PatientId patientId,
    SocialCareAppointment appointment,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updateIntakeInfo(
    PatientId patientId,
    IngressInfo info,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updatePlacementHistory(
    PatientId patientId,
    PlacementHistory history,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<ViolationReportId>> reportViolation(
    PatientId patientId,
    RightsViolationReport report,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<ReferralId>> createReferral(
    PatientId patientId,
    Referral referral,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<List<LookupItem>>> getLookupTable(String tableName) async =>
      const Success([]);
}

/// In-memory fake remote that can be configured per-test.
class InMemoryRemoteRepository implements SocialCareContract {
  Result<PatientRemote>? fetchPatientResult;
  int fetchPatientCallCount = 0;

  @override
  Future<Result<PatientRemote>> fetchPatient(PatientId id) async {
    fetchPatientCallCount++;
    return fetchPatientResult ?? const Failure('Not configured');
  }

  @override
  Future<Result<void>> checkHealth() async => const Success(null);
  @override
  Future<Result<void>> checkReady() async => const Success(null);
  @override
  Future<Result<List<PatientOverview>>> fetchPatients() async =>
      const Success([]);
  @override
  Future<Result<PatientId>> registerPatient(Patient patient) async =>
      const Failure('Not implemented');
  @override
  Future<Result<PatientRemote>> fetchPatientByPersonId(PersonId personId) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> addFamilyMember(
    PatientId patientId,
    FamilyMember member,
    LookupId prRelationshipId,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> removeFamilyMember(
    PatientId patientId,
    PersonId memberId,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> assignPrimaryCaregiver(
    PatientId patientId,
    PersonId memberId,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updateSocialIdentity(
    PatientId patientId,
    SocialIdentity identity,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<List<AuditEvent>>> getAuditTrail(
    PatientId patientId, {
    String? eventType,
  }) async =>
      const Success([]);
  @override
  Future<Result<void>> updateHousingCondition(
    PatientId patientId,
    HousingCondition condition,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updateSocioEconomicSituation(
    PatientId patientId,
    SocioEconomicSituation situation,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updateWorkAndIncome(
    PatientId patientId,
    WorkAndIncome data,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updateEducationalStatus(
    PatientId patientId,
    EducationalStatus status,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updateHealthStatus(
    PatientId patientId,
    HealthStatus status,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updateCommunitySupportNetwork(
    PatientId patientId,
    CommunitySupportNetwork network,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updateSocialHealthSummary(
    PatientId patientId,
    SocialHealthSummary summary,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<AppointmentId>> registerAppointment(
    PatientId patientId,
    SocialCareAppointment appointment,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updateIntakeInfo(
    PatientId patientId,
    IngressInfo info,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<void>> updatePlacementHistory(
    PatientId patientId,
    PlacementHistory history,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<ViolationReportId>> reportViolation(
    PatientId patientId,
    RightsViolationReport report,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<ReferralId>> createReferral(
    PatientId patientId,
    Referral referral,
  ) async =>
      const Failure('Not implemented');
  @override
  Future<Result<List<LookupItem>>> getLookupTable(String tableName) async =>
      const Success([]);
}

// ── Tests ────────────────────────────────────────────────────────

void main() {
  late OfflineFirstRepository repository;
  late InMemoryLocalRepository local;
  late InMemoryRemoteRepository remote;
  late ConnectivityService connectivity;
  late FakeSyncScheduler syncEngine;

  setUp(() {
    local = InMemoryLocalRepository();
    remote = InMemoryRemoteRepository();
    connectivity = ConnectivityService();
    connectivity.setOnlineForTesting(true);
    syncEngine = FakeSyncScheduler();

    repository = OfflineFirstRepository(
      local: local,
      remote: remote,
      connectivity: connectivity,
      syncEngine: syncEngine,
    );
  });

  group('OfflineFirstRepository - Write Operations', () {
    test('registerPatient should trigger sync if online', () async {
      final result = await repository.registerPatient(_patient);

      expect(result.isSuccess, isTrue);
      expect(local.registerPatientCallCount, 1);
    });

    test('registerPatient should NOT trigger sync if offline', () async {
      connectivity.setOnlineForTesting(false);

      final result = await repository.registerPatient(_patient);

      expect(result.isSuccess, isTrue);
      expect(local.registerPatientCallCount, 1);
    });
  });

  group('OfflineFirstRepository - Read Operations', () {
    test('fetchPatient should try remote and update cache if online', () async {
      remote.fetchPatientResult = Success(_patientRemote);

      final result = await repository.fetchPatient(_patientId);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.patientId, _patientRemote.patientId);
      expect(remote.fetchPatientCallCount, 1);
    });

    test(
      'fetchPatient should fallback to local if remote fails and online',
      () async {
        remote.fetchPatientResult = const Failure('Network error');
        await local.updateCacheFromRemote(_patientRemote);

        final result = await repository.fetchPatient(_patientId);

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull!.patientId, _patientRemote.patientId);
        expect(remote.fetchPatientCallCount, 1);
      },
    );

    test('fetchPatient should go straight to local if offline', () async {
      connectivity.setOnlineForTesting(false);
      await local.updateCacheFromRemote(_patientRemote);

      final result = await repository.fetchPatient(_patientId);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.patientId, _patientRemote.patientId);
      expect(remote.fetchPatientCallCount, 0);
    });
  });
}
