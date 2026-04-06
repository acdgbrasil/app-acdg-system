import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:network/network.dart';
import 'local_cache_contract.dart';

/// Orchestrator that implements [SocialCareContract] with an offline-first strategy.
///
/// Rules:
/// - Writes: Always local first, then trigger sync if online.
/// - Reads: Remote first if online (with cache update), fallback to local.
/// Minimal interface for scheduling sync queue processing.
///
/// Implemented by [SyncEngine] in production. Allows test doubles
/// without pulling in the full sync infrastructure.
abstract class SyncScheduler {
  void scheduleProcessQueue();
}

class OfflineFirstRepository implements SocialCareContract {
  final LocalCacheContract _local;
  final SocialCareContract _remote;
  final ConnectivityService _connectivity;
  final SyncScheduler _syncEngine;

  OfflineFirstRepository({
    required LocalCacheContract local,
    required SocialCareContract remote,
    required ConnectivityService connectivity,
    required SyncScheduler syncEngine,
  }) : _local = local,
       _remote = remote,
       _connectivity = connectivity,
       _syncEngine = syncEngine;

  bool get _isOnline => _connectivity.isOnline.value;

  // ==========================================
  // HELPERS
  // ==========================================

  Future<Result<T>> _handleWrite<T>(
    Future<Result<T>> Function() localCall,
  ) async {
    debugPrint('[Offline Repo] _handleWrite start');
    final result = await localCall();

    if (result.isSuccess) {
      debugPrint('[Offline Repo] _handleWrite SUCCESS locally. Checking sync...');
      if (_isOnline) {
        debugPrint('[Offline Repo] Online! Scheduling sync process...');
        _syncEngine.scheduleProcessQueue();
      } else {
        debugPrint('[Offline Repo] Offline. Action remained in queue.');
      }
    } else {
      debugPrint('[Offline Repo] _handleWrite FAILED locally: ${(result as Failure).error}');
    }

    return result;
  }

  Future<Result<T>> _handleRead<T>({
    required Future<Result<T>> Function() remoteCall,
    required Future<Result<T>> Function() localCall,
    Future<void> Function(T)? onRemoteSuccess,
  }) async {
    debugPrint('[Offline Repo] _handleRead start (Online: $_isOnline)');
    if (_isOnline) {
      debugPrint('[Offline Repo] Attempting remote call...');
      final remoteResult = await remoteCall();

      if (remoteResult case Success(:final value)) {
        debugPrint('[Offline Repo] Remote SUCCESS. Updating cache...');
        if (onRemoteSuccess != null) {
          unawaited(onRemoteSuccess(value));
        }
        return Success(value);
      } else {
        debugPrint('[Offline Repo] Remote FAILED: ${(remoteResult as Failure).error}. Falling back to local...');
      }
    }

    debugPrint('[Offline Repo] Returning local data...');
    return localCall();
  }

  // ==========================================
  // HEALTH
  // ==========================================

  @override
  Future<Result<void>> checkHealth() => _remote.checkHealth();

  @override
  Future<Result<void>> checkReady() => _remote.checkReady();

  // ==========================================
  // REGISTRY
  // ==========================================

  @override
  Future<Result<List<PatientOverview>>> fetchPatients() async {
    // Local-first for listing — the SyncEngine pull keeps cache fresh in background.
    // This avoids blocking the UI with a remote call every time the Home loads.
    final localResult = await _local.fetchPatients();
    if (localResult case Success(value: final items) when items.isNotEmpty) {
      return localResult;
    }
    // If local is empty and online, try remote
    if (_isOnline) {
      final remoteResult = await _remote.fetchPatients();
      if (remoteResult case Success(:final value)) {
        unawaited(_local.updateCacheFromSummaries(value));
        return remoteResult;
      }
    }
    return localResult;
  }

  @override
  Future<Result<PatientId>> registerPatient(Patient patient) =>
      _handleWrite(() => _local.registerPatient(patient));

  @override
  Future<Result<PatientRemote>> fetchPatient(PatientId id) async {
    final pending = await _local.hasPendingActions(id);

    if (pending) {
      debugPrint(
        '[Offline Repo] ⛔ Pending actions for patient ${id.value} — '
        'returning LOCAL as source of truth.',
      );
      return _local.fetchPatient(id);
    }

    return _handleRead(
      remoteCall: () => _remote.fetchPatient(id),
      localCall: () => _local.fetchPatient(id),
      onRemoteSuccess: (dto) async {
        final localResult = await _local.fetchPatient(id);
        if (localResult case Success(:final value)) {
          final localMembers = value.familyMembers.length;
          final remoteMembers = dto.familyMembers.length;
          if (remoteMembers < localMembers) {
            debugPrint(
              '[Offline Repo] ⚠️ DESYNC: Remote returned $remoteMembers members '
              'but local has $localMembers for patient ${id.value}. '
              'Possible sync lag or data loss.',
            );
          }
        }
        await _local.updateCacheFromRemote(dto);
      },
    );
  }

  @override
  Future<Result<PatientRemote>> fetchPatientByPersonId(PersonId personId) =>
      _handleRead(
        remoteCall: () => _remote.fetchPatientByPersonId(personId),
        localCall: () => _local.fetchPatientByPersonId(personId),
        onRemoteSuccess: (dto) => _local.updateCacheFromRemote(dto),
      );

  @override
  Future<Result<void>> addFamilyMember(
    PatientId patientId,
    FamilyMember member,
    LookupId prRelationshipId,
  ) => _handleWrite(
    () => _local.addFamilyMember(patientId, member, prRelationshipId),
  );

  @override
  Future<Result<void>> removeFamilyMember(
    PatientId patientId,
    PersonId memberId,
  ) => _handleWrite(() => _local.removeFamilyMember(patientId, memberId));

  @override
  Future<Result<void>> assignPrimaryCaregiver(
    PatientId patientId,
    PersonId memberId,
  ) => _handleWrite(() => _local.assignPrimaryCaregiver(patientId, memberId));

  @override
  Future<Result<void>> updateSocialIdentity(
    PatientId patientId,
    SocialIdentity identity,
  ) => _handleWrite(() => _local.updateSocialIdentity(patientId, identity));

  @override
  Future<Result<List<AuditEvent>>> getAuditTrail(
    PatientId patientId, {
    String? eventType,
  }) => _remote.getAuditTrail(patientId, eventType: eventType);

  // ==========================================
  // ASSESSMENT
  // ==========================================

  @override
  Future<Result<void>> updateHousingCondition(
    PatientId patientId,
    HousingCondition condition,
  ) => _handleWrite(() => _local.updateHousingCondition(patientId, condition));

  @override
  Future<Result<void>> updateSocioEconomicSituation(
    PatientId patientId,
    SocioEconomicSituation situation,
  ) => _handleWrite(
    () => _local.updateSocioEconomicSituation(patientId, situation),
  );

  @override
  Future<Result<void>> updateWorkAndIncome(
    PatientId patientId,
    WorkAndIncome data,
  ) => _handleWrite(() => _local.updateWorkAndIncome(patientId, data));

  @override
  Future<Result<void>> updateEducationalStatus(
    PatientId patientId,
    EducationalStatus status,
  ) => _handleWrite(() => _local.updateEducationalStatus(patientId, status));

  @override
  Future<Result<void>> updateHealthStatus(
    PatientId patientId,
    HealthStatus status,
  ) => _handleWrite(() => _local.updateHealthStatus(patientId, status));

  @override
  Future<Result<void>> updateCommunitySupportNetwork(
    PatientId patientId,
    CommunitySupportNetwork network,
  ) => _handleWrite(
    () => _local.updateCommunitySupportNetwork(patientId, network),
  );

  @override
  Future<Result<void>> updateSocialHealthSummary(
    PatientId patientId,
    SocialHealthSummary summary,
  ) => _handleWrite(() => _local.updateSocialHealthSummary(patientId, summary));

  // ==========================================
  // CARE
  // ==========================================

  @override
  Future<Result<AppointmentId>> registerAppointment(
    PatientId patientId,
    SocialCareAppointment appointment,
  ) => _handleWrite(() => _local.registerAppointment(patientId, appointment));

  @override
  Future<Result<void>> updateIntakeInfo(
    PatientId patientId,
    IngressInfo info,
  ) => _handleWrite(() => _local.updateIntakeInfo(patientId, info));

  // ==========================================
  // PROTECTION
  // ==========================================

  @override
  Future<Result<void>> updatePlacementHistory(
    PatientId patientId,
    PlacementHistory history,
  ) => _handleWrite(() => _local.updatePlacementHistory(patientId, history));

  @override
  Future<Result<ViolationReportId>> reportViolation(
    PatientId patientId,
    RightsViolationReport report,
  ) => _handleWrite(() => _local.reportViolation(patientId, report));

  @override
  Future<Result<ReferralId>> createReferral(
    PatientId patientId,
    Referral referral,
  ) => _handleWrite(() => _local.createReferral(patientId, referral));

  // ==========================================
  // LOOKUP
  // ==========================================

  @override
  Future<Result<List<LookupItem>>> getLookupTable(String tableName) async {
    debugPrint('[Offline Repo] getLookupTable for: $tableName');
    final localResult = await _local.getLookupTable(tableName);

    if (localResult case Success(value: final items) when items.isNotEmpty) {
      debugPrint('[Offline Repo] Returning ${items.length} items from LOCAL cache for $tableName');
      return Success(items);
    }

    debugPrint('[Offline Repo] Local cache EMPTY for $tableName. Checking online...');
    if (_isOnline) {
      debugPrint('[Offline Repo] Online! Fetching $tableName from REMOTE...');
      final remoteResult = await _remote.getLookupTable(tableName);
      if (remoteResult case Success(:final value)) {
        debugPrint('[Offline Repo] Remote SUCCESS for $tableName. Updating local cache...');
        unawaited(_local.updateLookupCache(tableName, value));
        return Success(value);
      } else {
        debugPrint('[Offline Repo] Remote FAILED for $tableName: ${(remoteResult as Failure).error}');
      }
    }

    debugPrint('[Offline Repo] Returning local result (likely empty or failure)');
    return localResult;
  }

  /// Manually pre-fetches all common lookup tables.
  Future<void> prefetchLookupTables() async {
    if (!_isOnline) return;

    final tables = [
      'dominio_tipo_identidade',
      'dominio_parentesco',
      'dominio_condicao_ocupacao',
      'dominio_escolaridade',
      'dominio_efeito_condicionalidade',
      'dominio_tipo_deficiencia',
      'dominio_programa_social',
      'dominio_tipo_ingresso',
      'dominio_tipo_beneficio',
      'dominio_tipo_violacao',
      'dominio_servico_vinculo',
      'dominio_tipo_medida',
      'dominio_unidade_realizacao',
    ];

    for (final table in tables) {
      final result = await _remote.getLookupTable(table);
      if (result case Success(:final value)) {
        await _local.updateLookupCache(table, value);
      }
    }
  }
}
