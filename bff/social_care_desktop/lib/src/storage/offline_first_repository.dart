import 'dart:async';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:network/network.dart';
import 'local_cache_contract.dart';

abstract class SyncScheduler {
  void scheduleProcessQueue();
}

class OfflineFirstRepository implements SocialCareContract {
  static final _log = AcdgLogger.get('OfflineFirstRepository');
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

  Future<Result<T>> _handleWrite<T>(Future<Result<T>> Function() localCall) async {
    final result = await localCall();
    if (result.isSuccess) {
      if (_isOnline) {
        _log.fine('Write succeeded locally, scheduling sync');
        _syncEngine.scheduleProcessQueue();
      }
    }
    return result;
  }

  Future<Result<T>> _handleRead<T>({
    required Future<Result<T>> Function() remoteCall,
    required Future<Result<T>> Function() localCall,
    Future<void> Function(T)? onRemoteSuccess,
  }) async {
    if (_isOnline) {
      final remoteResult = await remoteCall();
      if (remoteResult case Success(:final value)) {
        if (onRemoteSuccess != null) unawaited(onRemoteSuccess(value));
        return remoteResult;
      }
      _log.warning('Remote read failed, falling back to local');
    }
    return localCall();
  }

  @override Future<Result<void>> checkHealth() => _remote.checkHealth();
  @override Future<Result<void>> checkReady() => _remote.checkReady();

  // Registry
  @override
  Future<Result<PaginatedList<PatientSummaryResponse>>> fetchPatients({
    String? cursor, int? limit, String? search, String? status,
  }) async {
    final localResult = await _local.fetchPatients(cursor: cursor, limit: limit, search: search, status: status);
    if (localResult case Success(value: final items) when items.data.isNotEmpty) {
      return localResult;
    }
    if (_isOnline) {
      final remoteResult = await _remote.fetchPatients(cursor: cursor, limit: limit, search: search, status: status);
      if (remoteResult case Success(:final value)) {
        unawaited(_local.updateCacheFromSummaries(value.data));
        return remoteResult;
      }
    }
    return localResult;
  }

  @override
  Future<Result<StandardIdResponse>> registerPatient(RegisterPatientRequest request) =>
      _handleWrite(() => _local.registerPatient(request));

  @override
  Future<Result<StandardResponse<PatientResponse>>> fetchPatient(String id) async {
    final pending = await _local.hasPendingActions(id);
    if (pending) return _local.fetchPatient(id);

    return _handleRead(
      remoteCall: () => _remote.fetchPatient(id),
      localCall: () => _local.fetchPatient(id),
      onRemoteSuccess: (response) => _local.updateCacheFromRemote(response.data),
    );
  }

  @override
  Future<Result<StandardResponse<PatientResponse>>> fetchPatientByPersonId(String personId) =>
      _handleRead(
        remoteCall: () => _remote.fetchPatientByPersonId(personId),
        localCall: () => _local.fetchPatientByPersonId(personId),
        onRemoteSuccess: (response) => _local.updateCacheFromRemote(response.data),
      );

  @override
  Future<Result<void>> addFamilyMember(String patientId, AddFamilyMemberRequest request, {String? cpf}) =>
      _handleWrite(() => _local.addFamilyMember(patientId, request, cpf: cpf));

  @override
  Future<Result<void>> removeFamilyMember(String patientId, String memberId) =>
      _handleWrite(() => _local.removeFamilyMember(patientId, memberId));

  @override
  Future<Result<void>> assignPrimaryCaregiver(String patientId, AssignPrimaryCaregiverRequest request) =>
      _handleWrite(() => _local.assignPrimaryCaregiver(patientId, request));

  @override
  Future<Result<void>> updateSocialIdentity(String patientId, UpdateSocialIdentityRequest request) =>
      _handleWrite(() => _local.updateSocialIdentity(patientId, request));

  @override
  Future<Result<StandardResponse<List<AuditTrailEntryResponse>>>> getAuditTrail(String patientId, {String? eventType, int? limit, int? offset}) =>
      _remote.getAuditTrail(patientId, eventType: eventType, limit: limit, offset: offset);

  // Assessment
  @override
  Future<Result<void>> updateHousingCondition(String patientId, UpdateHousingConditionRequest request) =>
      _handleWrite(() => _local.updateHousingCondition(patientId, request));

  @override
  Future<Result<void>> updateSocioEconomicSituation(String patientId, UpdateSocioEconomicSituationRequest request) =>
      _handleWrite(() => _local.updateSocioEconomicSituation(patientId, request));

  @override
  Future<Result<void>> updateWorkAndIncome(String patientId, UpdateWorkAndIncomeRequest request) =>
      _handleWrite(() => _local.updateWorkAndIncome(patientId, request));

  @override
  Future<Result<void>> updateEducationalStatus(String patientId, UpdateEducationalStatusRequest request) =>
      _handleWrite(() => _local.updateEducationalStatus(patientId, request));

  @override
  Future<Result<void>> updateHealthStatus(String patientId, UpdateHealthStatusRequest request) =>
      _handleWrite(() => _local.updateHealthStatus(patientId, request));

  @override
  Future<Result<void>> updateCommunitySupportNetwork(String patientId, UpdateCommunitySupportNetworkRequest request) =>
      _handleWrite(() => _local.updateCommunitySupportNetwork(patientId, request));

  @override
  Future<Result<void>> updateSocialHealthSummary(String patientId, UpdateSocialHealthSummaryRequest request) =>
      _handleWrite(() => _local.updateSocialHealthSummary(patientId, request));

  // Care
  @override
  Future<Result<StandardResponse<IdData>>> registerAppointment(String patientId, RegisterAppointmentRequest request) =>
      _handleWrite(() => _local.registerAppointment(patientId, request));

  @override
  Future<Result<void>> updateIntakeInfo(String patientId, RegisterIntakeInfoRequest request) =>
      _handleWrite(() => _local.updateIntakeInfo(patientId, request));

  // Protection
  @override
  Future<Result<void>> updatePlacementHistory(String patientId, UpdatePlacementHistoryRequest request) =>
      _handleWrite(() => _local.updatePlacementHistory(patientId, request));

  @override
  Future<Result<StandardResponse<IdData>>> reportViolation(String patientId, ReportRightsViolationRequest request) =>
      _handleWrite(() => _local.reportViolation(patientId, request));

  @override
  Future<Result<StandardResponse<IdData>>> createReferral(String patientId, CreateReferralRequest request) =>
      _handleWrite(() => _local.createReferral(patientId, request));

  // Lookups
  @override
  Future<Result<StandardResponse<List<Map<String, dynamic>>>>> getLookupTable(String tableName) async {
    final localResult = await _local.getLookupTable(tableName);
    if (localResult case Success(value: final items) when items.data.isNotEmpty) {
      return localResult;
    }
    if (_isOnline) {
      final remoteResult = await _remote.getLookupTable(tableName);
      if (remoteResult case Success(:final value)) {
        unawaited(_local.updateLookupCache(tableName, value.data));
        return remoteResult;
      }
    }
    return localResult;
  }

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
        await _local.updateLookupCache(table, value.data);
      }
    }
  }

  // Analytics
  @override
  Future<Result<StandardResponse<IndicatorResponse>>> getIndicators(String axisId, {String? period}) => _remote.getIndicators(axisId, period: period);
  
  @override
  Future<Result<StandardResponse<List<AxisMetadataResponse>>>> getAxesMetadata() => _remote.getAxesMetadata();

  // System
  @override
  
  @override

  // People
  @override
  Future<Result<StandardIdResponse>> registerPerson(RegisterPersonRequest request) => _remote.registerPerson(request);
  
  @override
  Future<Result<StandardIdResponse>> registerPersonWithLogin(RegisterPersonWithLoginRequest request) => _remote.registerPersonWithLogin(request);
  
  @override
  Future<Result<PersonResponse>> getPerson(String personId) => _remote.getPerson(personId);
  
  @override
  Future<Result<PersonResponse>> findPersonByCpf(String cpf) => _remote.findPersonByCpf(cpf);
  
  @override
  Future<Result<StandardResponse<List<PersonResponse>>>> fetchPeople({String? cpf, String? cursor, int? limit, String? name}) => _remote.fetchPeople(cpf: cpf, cursor: cursor, limit: limit, name: name);
  
  @override
  Future<Result<void>> deactivatePerson(String personId) => _remote.deactivatePerson(personId);
  
  @override
  Future<Result<void>> reactivatePerson(String personId) => _remote.reactivatePerson(personId);
  
  @override
  Future<Result<void>> requestPasswordReset(String personId) => _remote.requestPasswordReset(personId);
  
  @override
  Future<Result<void>> assignRole(String personId, AssignRoleRequest request) => _remote.assignRole(personId, request);
  
  @override
  Future<Result<List<PersonRoleResponse>>> listPersonRoles(String personId, {bool? active}) => _remote.listPersonRoles(personId, active: active);
  
  @override
  Future<Result<List<PersonRoleResponse>>> queryRoles({bool active = true, String? role, required String system}) => _remote.queryRoles(active: active, role: role, system: system);
  
  @override
  Future<Result<void>> deactivateRole({required String personId, required String roleId}) => _remote.deactivateRole(personId: personId, roleId: roleId);
  
  @override
  Future<Result<void>> reactivateRole({required String personId, required String roleId}) => _remote.reactivateRole(personId: personId, roleId: roleId);

  // Registry additions
  @override
  Future<Result<void>> dischargePatient(String patientId, DischargePatientRequest request) => _remote.dischargePatient(patientId, request);
  
  @override
  Future<Result<void>> readmitPatient(String patientId, ReadmitPatientRequest request) => _remote.readmitPatient(patientId, request);
  
  @override
  Future<Result<void>> admitPatient(String patientId) => _remote.admitPatient(patientId);
  
  @override
  Future<Result<void>> withdrawPatient(String patientId, WithdrawPatientRequest request) => _remote.withdrawPatient(patientId, request);


  @override
  Future<Result<StandardIdResponse>> createLookupItem(String tableName, Map<String, dynamic> request) => _remote.createLookupItem(tableName, request);
  @override
  Future<Result<void>> updateLookupItem(String tableName, String id, Map<String, dynamic> request) => _remote.updateLookupItem(tableName, id, request);
  @override
  Future<Result<void>> toggleLookupItem(String tableName, String id, bool activate) => _remote.toggleLookupItem(tableName, id, activate);
  @override
  Future<Result<StandardResponse<List<Map<String, dynamic>>>>> getLookupRequests() => _remote.getLookupRequests();
  @override
  Future<Result<StandardIdResponse>> createLookupRequest(Map<String, dynamic> request) => _remote.createLookupRequest(request);
  @override
  Future<Result<void>> approveLookupRequest(String requestId) => _remote.approveLookupRequest(requestId);
  @override
  Future<Result<void>> rejectLookupRequest(String requestId) => _remote.rejectLookupRequest(requestId);
  @override
  Future<Result<StandardResponse<PatientResponse>>> fetchPatientEnriched(String patientId) => _remote.fetchPatientEnriched(patientId);

}
