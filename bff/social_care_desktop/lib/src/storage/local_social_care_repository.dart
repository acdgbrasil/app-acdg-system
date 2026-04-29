import 'dart:convert';

import 'package:core/core.dart';
import 'package:core/core_offline.dart';
import 'package:drift/drift.dart';
import 'package:persistence/persistence.dart';
import 'package:shared/shared.dart';

import 'local_cache_contract.dart';

/// Implementation of [LocalCacheContract] that uses Drift for local storage
/// and enqueues actions for synchronization.
class LocalSocialCareRepository implements LocalCacheContract {
  static final _log = AcdgLogger.get('LocalSocialCareRepository');
  final DriftDatabaseService _dbService;
  final SyncQueueService _queueService;

  LocalSocialCareRepository({
    required DriftDatabaseService dbService,
    required SyncQueueService queueService,
  }) : _dbService = dbService,
       _queueService = queueService;

  AcdgDatabase get _db => _dbService.db;

  // ==========================================
  // HELPERS
  // ==========================================

  Future<Result<void>> _mutatePatientRaw(
    String patientId,
    String actionType,
    Map<String, dynamic> actionPayload,
    Map<String, dynamic> Function(Map<String, dynamic>) mutator,
  ) async {
    _log.fine('_mutatePatientRaw: $actionType for $patientId');
    try {
      final cached = await (_db.select(
        _db.cachedPatients,
      )..where((t) => t.patientId.equals(patientId))).getSingleOrNull();

      if (cached == null) {
        _log.warning('Patient not found in cache: $patientId');
        return Failure(_notFoundError('Patient not found in local cache'));
      }

      final currentJson =
          jsonDecode(cached.fullRecordJson) as Map<String, dynamic>;
          
      final updatedJson = mutator(currentJson);

      await (_db.update(
        _db.cachedPatients,
      )..where((t) => t.patientId.equals(patientId))).write(
        CachedPatientsCompanion(
          fullRecordJson: Value(jsonEncode(updatedJson)),
          version: Value(cached.version + 1),
          isDirty: const Value(true),
          lastSyncAt: Value(DateTime.now().toUtc()),
        ),
      );

      _log.fine('Enqueueing sync action: $actionType');
      await _queueService.enqueue(
        patientId: patientId,
        actionType: actionType,
        payload: actionPayload,
      );

      return const Success(null);
    } catch (e, st) {
      _log.severe('CRITICAL: _mutatePatientRaw failed ($actionType)', e, st);
      return Failure(BackendError(id: '', code: 'LOC-500', message: 'Mutation failed: $e'));
    }
  }

  static AppError _notFoundError(String message) => AppError(
    code: 'LOC-404',
    message: message,
    module: 'social-care/local-repo',
    kind: 'notFound',
    observability: const Observability(
      category: ErrorCategory.domainRuleViolation,
      severity: ErrorSeverity.warning,
    ),
  );

  // ==========================================
  // CACHE MANAGEMENT (Internal/OfflineFirst)
  // ==========================================

  /// Updates the local cache without enqueuing a sync action.
  /// Used by OfflineFirstRepository when fresh data comes from remote.
  Future<void> updateCache(Patient patient) async {
    final fullJson = PatientTranslator.toJson(patient);

    await _db
        .into(_db.cachedPatients)
        .insert(
          CachedPatientsCompanion.insert(
            patientId: patient.id.value,
            personId: patient.personId.value,
            firstName: Value(patient.personalData?.firstName ?? ''),
            lastName: Value(patient.personalData?.lastName ?? ''),
            cpf: Value(patient.civilDocuments?.cpf?.value ?? ''),
            fullRecordJson: jsonEncode(fullJson),
            version: Value(patient.version),
            isDirty: const Value(false),
            lastSyncAt: DateTime.now().toUtc(),
          ),
          onConflict: DoUpdate(
            (old) => CachedPatientsCompanion(
              personId: Value(patient.personId.value),
              firstName: Value(patient.personalData?.firstName ?? ''),
              lastName: Value(patient.personalData?.lastName ?? ''),
              cpf: Value(patient.civilDocuments?.cpf?.value ?? ''),
              fullRecordJson: Value(jsonEncode(fullJson)),
              version: Value(patient.version),
              isDirty: const Value(false),
              lastSyncAt: Value(DateTime.now().toUtc()),
            ),
            target: [_db.cachedPatients.patientId],
          ),
        );
  }

  /// Updates a lookup table cache.
  @override
  Future<void> updateLookupCache(
    String tableName,
    List<Map<String, dynamic>> items,
  ) async {
    final itemsJson = jsonEncode(items);

    await _db
        .into(_db.cachedLookups)
        .insert(
          CachedLookupsCompanion.insert(
            lookupName: tableName,
            itemsJson: itemsJson,
            lastFetchedAt: DateTime.now().toUtc(),
          ),
          onConflict: DoUpdate(
            (old) => CachedLookupsCompanion(
              itemsJson: Value(itemsJson),
              lastFetchedAt: Value(DateTime.now().toUtc()),
            ),
            target: [_db.cachedLookups.lookupName],
          ),
        );
  }

  // ==========================================
  // HEALTH
  // ==========================================

  @override
  Future<Result<void>> checkHealth() async => const Success(null);

  @override
  Future<Result<void>> checkReady() async {
    if (_dbService.isOpen) return const Success(null);
    return Failure(
      AppError(
        code: 'DB_CLOSED',
        message: 'Base de dados local está fechada',
        module: 'local-repository',
        kind: 'infrastructure',
        observability: const Observability(
          category: ErrorCategory.infrastructureDependencyFailure,
          severity: ErrorSeverity.error,
        ),
      ),
    );
  }

  /// Bulk-updates local cache from server summaries without enqueuing sync actions.
  @override
  @override
  Future<void> updateCacheFromSummaries(List<PatientSummaryResponse> summaries) async {
    final existingPatients = await _db.select(_db.cachedPatients).get();
    final existingMap = {for (final c in existingPatients) c.patientId: c};

    await _db.batch((batch) {
      for (final item in summaries) {
        final id = item.patientId;
        final existing = existingMap[id];
        final shouldPreserveRecord =
            existing != null && _isFullRecord(existing.fullRecordJson);

        batch.insert(
          _db.cachedPatients,
          CachedPatientsCompanion.insert(
            patientId: id,
            personId: item.personId.isNotEmpty
                ? item.personId
                : existing?.personId ?? '',
            firstName: Value(item.fullName?.split(' ').first ?? ''),
            lastName: Value(item.fullName?.split(' ').skip(1).join(' ') ?? ''),
            cpf: Value(existing?.cpf ?? ''),
            fullRecordJson: shouldPreserveRecord
                ? existing.fullRecordJson
                : jsonEncode(item.toJson()),
            version: Value(existing?.version ?? 0),
            isDirty: Value(existing?.isDirty ?? false),
            lastSyncAt: DateTime.now().toUtc(),
          ),
          onConflict: DoUpdate(
            (old) => CachedPatientsCompanion(
              personId: Value(
                item.personId.isNotEmpty
                    ? item.personId
                    : existing?.personId ?? '',
              ),
              firstName: Value(item.fullName?.split(' ').first ?? ''),
              lastName: Value(item.fullName?.split(' ').skip(1).join(' ') ?? ''),
              fullRecordJson: shouldPreserveRecord
                  ? Value(existing.fullRecordJson)
                  : Value(jsonEncode(item.toJson())),
              lastSyncAt: Value(DateTime.now().toUtc()),
            ),
          ),
        );
      }
    });
  }

  /// Checks whether there are pending sync actions for a given patient.
  @override
  Future<bool> hasPendingActions(String patientId) async {
    final actions = await _queueService.getPendingActions();
    return actions.any((a) => a.patientId == patientId);
  }

  /// Updates the local cache from a [PatientRemote] without enqueuing a sync action.
  @override
  Future<void> updateCacheFromRemote(PatientResponse dto) async {
    final fullJson = dto.toJson();
    final pd = dto.personalData;

    await _db
        .into(_db.cachedPatients)
        .insert(
          CachedPatientsCompanion.insert(
            patientId: dto.patientId,
            personId: dto.personId,
            firstName: Value(pd?.firstName ?? ''),
            lastName: Value(pd?.lastName ?? ''),
            cpf: Value(''),
            fullRecordJson: jsonEncode(fullJson),
            version: Value(dto.version),
            isDirty: const Value(false),
            lastSyncAt: DateTime.now().toUtc(),
          ),
          onConflict: DoUpdate(
            (old) => CachedPatientsCompanion(
              personId: Value(dto.personId),
              firstName: Value(pd?.firstName ?? ''),
              lastName: Value(pd?.lastName ?? ''),
              fullRecordJson: Value(jsonEncode(fullJson)),
              version: Value(dto.version),
              isDirty: const Value(false),
              lastSyncAt: Value(DateTime.now().toUtc()),
            ),
            target: [_db.cachedPatients.patientId],
          ),
        );
  }

  bool _isFullRecord(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map.containsKey('prRelationshipId');
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // REGISTRY
  // ==========================================

  @override
  Future<Result<PaginatedList<PatientSummaryResponse>>> fetchPatients({
    String? cursor,
    int? limit,
    String? search,
    String? status,
  }) async {
    try {
      final allCached = await _db.select(_db.cachedPatients).get();
      final summaries = allCached.map(_toSummaryDTO).toList();
      return Success(PaginatedList(
        data: summaries,
        meta: PaginationMeta(
          totalCount: summaries.length,
          pageSize: limit ?? 50,
          hasMore: false,
        ),
      ));
    } catch (e) {
      return Failure(BackendError(id: '', code: 'LOCAL_READ_ERR', message: e.toString()));
    }
  }

  PatientSummaryResponse _toSummaryDTO(CachedPatient c) {
    try {
      final json = jsonDecode(c.fullRecordJson) as Map<String, dynamic>;

      if (json.containsKey('prRelationshipId')) {
        final pd = json['personalData'] as Map<String, dynamic>?;
        final diagnoses =
            (json['diagnoses'] as List?) ??
            (json['initialDiagnoses'] as List?) ??
            [];
        final firstName = pd?['firstName'] as String? ?? c.firstName;
        final lastName = pd?['lastName'] as String? ?? c.lastName;

        return PatientSummaryResponse(
          patientId: json['patientId'] as String? ?? c.patientId,
          personId: json['personId'] as String? ?? c.personId,
          firstName: firstName,
          lastName: lastName,
          fullName: '$firstName $lastName'.trim(),
          primaryDiagnosis: diagnoses.isNotEmpty
              ? (diagnoses.first as Map<String, dynamic>)['description']
                    as String?
              : null,
        );
      }

      return PatientSummaryResponse.fromJson(json);
    } catch (_) {
      return PatientSummaryResponse(
        patientId: c.patientId,
        personId: c.personId,
        firstName: c.firstName,
        lastName: c.lastName,
        fullName: '${c.firstName} ${c.lastName}'.trim(),
      );
    }
  }

  @override
  Future<Result<StandardIdResponse>> registerPatient(RegisterPatientRequest request) async {
    try {
      final tempId = 'LOCAL-${DateTime.now().millisecondsSinceEpoch}';

      final fullJson = request.toJson();

      await _db
          .into(_db.cachedPatients)
          .insert(
            CachedPatientsCompanion.insert(
              patientId: tempId,
              personId: request.personId,
              firstName: Value(request.personalData?.firstName ?? ''),
              lastName: Value(request.personalData?.lastName ?? ''),
              cpf: Value(request.civilDocuments?.cpf ?? ''),
              fullRecordJson: jsonEncode(fullJson),
              version: const Value(1),
              isDirty: const Value(true),
              lastSyncAt: DateTime.now().toUtc(),
            ),
          );

      await _queueService.enqueue(
        patientId: tempId,
        actionType: 'REGISTER_PATIENT',
        payload: fullJson,
      );

      return Success(
        StandardResponse(
          data: IdData(id: tempId),
          meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
        )
      );
    } catch (e) {
      return Failure(BackendError(id: '', code: 'LOCAL_WRITE_ERR', message: e.toString()));
    }
  }

  @override
  Future<Result<StandardResponse<PatientResponse>>> fetchPatient(String id) async {
    try {
      final cached = await (_db.select(
        _db.cachedPatients,
      )..where((t) => t.patientId.equals(id))).getSingleOrNull();

      if (cached == null) {
        return Failure(_notFoundError('Patient not found in local cache'));
      }

      final json = jsonDecode(cached.fullRecordJson) as Map<String, dynamic>;
      return Success(StandardResponse(meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()), data: PatientResponse.fromJson(json)));
    } catch (e) {
      return Failure(BackendError(id: '', code: 'LOCAL_READ_ERR', message: e.toString()));
    }
  }

  @override
  Future<Result<StandardResponse<PatientResponse>>> fetchPatientByPersonId(
    String personId,
  ) async {
    try {
      final cached = await (_db.select(
        _db.cachedPatients,
      )..where((t) => t.personId.equals(personId))).getSingleOrNull();

      if (cached == null) {
        return Failure(
          _notFoundError('Patient not found in local cache by personId'),
        );
      }

      final json = jsonDecode(cached.fullRecordJson) as Map<String, dynamic>;
      return Success(StandardResponse(meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()), data: PatientResponse.fromJson(json)));
    } catch (e) {
      return Failure(BackendError(id: '', code: 'LOCAL_READ_ERR', message: e.toString()));
    }
  }

  @override
  Future<Result<void>> addFamilyMember(
    String patientId,
    AddFamilyMemberRequest request, {
    String? cpf,
  }) async {
    final result = await _mutatePatientRaw(
      patientId,
      'ADD_FAMILY_MEMBER',
      {
        'patientId': patientId,
        'request': request.toJson(),
        if (cpf != null) 'cpf': cpf,
      },
      (jsonMap) {
        final members = (jsonMap['familyMembers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        members.add(request.toJson()); // Sync mock saves raw request
        jsonMap['familyMembers'] = members;
        return jsonMap;
      },
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> removeFamilyMember(
    String patientId,
    String memberId,
  ) async {
    final result = await _mutatePatientRaw(
      patientId,
      'REMOVE_FAMILY_MEMBER',
      {'patientId': patientId, 'memberId': memberId},
      (jsonMap) {
        final members = (jsonMap['familyMembers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        jsonMap['familyMembers'] = members.where((m) => m['personId'] != memberId).toList();
        return jsonMap;
      },
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> assignPrimaryCaregiver(
    String patientId,
    AssignPrimaryCaregiverRequest request,
  ) async {
    final result = await _mutatePatientRaw(
      patientId,
      'ASSIGN_CAREGIVER',
      {'patientId': patientId, 'request': request.toJson()},
      (jsonMap) {
        final members = (jsonMap['familyMembers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        for (var m in members) m['isPrimaryCaregiver'] = m['personId'] == request.memberPersonId;
        jsonMap['familyMembers'] = members;
        return jsonMap;
      },
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateSocialIdentity(
    String patientId,
    UpdateSocialIdentityRequest request,
  ) async {
    final result = await _mutatePatientRaw(
      patientId,
      'UPDATE_SOCIAL_IDENTITY',
      {
        'patientId': patientId,
        'identity': request.toJson(),
      },
      (jsonMap) {
        jsonMap['socialIdentity'] = request.toJson();
        return jsonMap;
      },
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<StandardResponse<List<AuditTrailEntryResponse>>>> getAuditTrail(
    String patientId, {
    String? eventType,
    int? limit,
    int? offset,
  }) async {
    return Success(StandardResponse(meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()), data: []));
  }

  // ==========================================
  // ASSESSMENT
  // ==========================================

  @override
  Future<Result<void>> updateHousingCondition(
    String patientId,
    UpdateHousingConditionRequest request,
  ) async {
    final result = await _mutatePatientRaw(
      patientId,
      'UPDATE_HOUSING',
      request.toJson(),
      (jsonMap) {
        jsonMap['housingCondition'] = request.toJson();
        return jsonMap;
      },
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateSocioEconomicSituation(
    String patientId,
    UpdateSocioEconomicSituationRequest request,
  ) async {
    final result = await _mutatePatientRaw(
      patientId,
      'UPDATE_SOCIOECONOMIC',
      request.toJson(),
      (jsonMap) {
        jsonMap['socioeconomicSituation'] = request.toJson();
        return jsonMap;
      },
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateWorkAndIncome(
    String patientId,
    UpdateWorkAndIncomeRequest request,
  ) async {
    final result = await _mutatePatientRaw(
      patientId,
      'UPDATE_WORK_INCOME',
      request.toJson(),
      (jsonMap) {
        jsonMap['workAndIncome'] = request.toJson();
        return jsonMap;
      },
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateEducationalStatus(
    String patientId,
    UpdateEducationalStatusRequest request,
  ) async {
    final result = await _mutatePatientRaw(
      patientId,
      'UPDATE_EDUCATION',
      request.toJson(),
      (jsonMap) {
        jsonMap['educationalStatus'] = request.toJson();
        return jsonMap;
      },
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateHealthStatus(
    String patientId,
    UpdateHealthStatusRequest request,
  ) async {
    final result = await _mutatePatientRaw(
      patientId,
      'UPDATE_HEALTH',
      request.toJson(),
      (jsonMap) {
        jsonMap['healthStatus'] = request.toJson();
        return jsonMap;
      },
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateCommunitySupportNetwork(
    String patientId,
    UpdateCommunitySupportNetworkRequest request,
  ) async {
    final result = await _mutatePatientRaw(
      patientId,
      'UPDATE_COMMUNITY_SUPPORT',
      request.toJson(),
      (jsonMap) {
        jsonMap['communitySupportNetwork'] = request.toJson();
        return jsonMap;
      },
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateSocialHealthSummary(
    String patientId,
    UpdateSocialHealthSummaryRequest request,
  ) async {
    final result = await _mutatePatientRaw(
      patientId,
      'UPDATE_SOCIAL_HEALTH',
      request.toJson(),
      (jsonMap) {
        jsonMap['socialHealthSummary'] = request.toJson();
        return jsonMap;
      },
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  // ==========================================
  // CARE
  // ==========================================

  @override
  Future<Result<StandardResponse<IdData>>> registerAppointment(
    String patientId,
    RegisterAppointmentRequest request,
  ) async {
    final tempId = 'LOCAL-APPT-${DateTime.now().millisecondsSinceEpoch}';
    final result = await _mutatePatientRaw(
      patientId,
      'REGISTER_APPOINTMENT',
      {
        'patientId': patientId,
        'request': request.toJson(),
      },
      (jsonMap) {
        final list = (jsonMap['appointments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        list.add({'id': tempId, ...request.toJson()});
        jsonMap['appointments'] = list;
        return jsonMap;
      },
    );

    if (result case Failure(:final error)) return Failure(error);
    return Success(StandardResponse(meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()), data: IdData(id: tempId)));
  }

  @override
  Future<Result<void>> updateIntakeInfo(
    String patientId,
    RegisterIntakeInfoRequest request,
  ) async {
    final result = await _mutatePatientRaw(
      patientId, 
      'UPDATE_INTAKE', 
      {
        'patientId': patientId,
        'request': request.toJson(),
      },
      (jsonMap) {
        jsonMap['intakeInfo'] = request.toJson();
        return jsonMap;
      }
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  // ==========================================
  // PROTECTION
  // ==========================================

  @override
  Future<Result<void>> updatePlacementHistory(
    String patientId,
    UpdatePlacementHistoryRequest request,
  ) async {
    final result = await _mutatePatientRaw(
      patientId,
      'UPDATE_PLACEMENT',
      request.toJson(),
      (jsonMap) {
        jsonMap['placementHistory'] = request.toJson();
        return jsonMap;
      },
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<StandardResponse<IdData>>> reportViolation(
    String patientId,
    ReportRightsViolationRequest request,
  ) async {
    final tempId = 'LOCAL-VIOL-${DateTime.now().millisecondsSinceEpoch}';
    final result = await _mutatePatientRaw(
      patientId,
      'REPORT_VIOLATION',
      {
        'patientId': patientId,
        'request': request.toJson(),
      },
      (jsonMap) {
        final list = (jsonMap['violationReports'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        list.add({'id': tempId, ...request.toJson()});
        jsonMap['violationReports'] = list;
        return jsonMap;
      },
    );

    if (result case Failure(:final error)) return Failure(error);
    return Success(StandardResponse(meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()), data: IdData(id: tempId)));
  }

  @override
  Future<Result<StandardResponse<IdData>>> createReferral(
    String patientId,
    CreateReferralRequest request,
  ) async {
    final tempId = 'LOCAL-REF-${DateTime.now().millisecondsSinceEpoch}';
    final result = await _mutatePatientRaw(
      patientId,
      'CREATE_REFERRAL',
      {
        'patientId': patientId,
        'request': request.toJson(),
      },
      (jsonMap) {
        final list = (jsonMap['referrals'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        list.add({'id': tempId, ...request.toJson()});
        jsonMap['referrals'] = list;
        return jsonMap;
      },
    );

    if (result case Failure(:final error)) return Failure(error);
    return Success(StandardResponse(meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()), data: IdData(id: tempId)));
  }

  // ==========================================
  // LOOKUP
  // ==========================================

  @override
  Future<Result<StandardResponse<List<Map<String, dynamic>>>>> getLookupTable(String tableName) async {
    try {
      final cached = await (_db.select(
        _db.cachedLookups,
      )..where((t) => t.lookupName.equals(tableName))).getSingleOrNull();

      if (cached == null) {
        return Success(StandardResponse(meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()), data: []));
      }

      final List<dynamic> list = jsonDecode(cached.itemsJson);
      final maps = list.cast<Map<String, dynamic>>();

      return Success(StandardResponse(meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()), data: maps));
    } catch (e) {
      return Failure(BackendError(id: '', code: 'LOCAL_LOOKUP_ERR', message: e.toString()));
    }
  }

  // Analytics
  @override
  Future<Result<StandardResponse<IndicatorResponse>>> getIndicators(String axisId, {String? period}) async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  
  @override
  Future<Result<StandardResponse<List<AxisMetadataResponse>>>> getAxesMetadata()  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));

  // System
  @override
  
  @override

  // People
  @override
  Future<Result<StandardIdResponse>> registerPerson(RegisterPersonRequest request)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  
  @override
  Future<Result<StandardIdResponse>> registerPersonWithLogin(RegisterPersonWithLoginRequest request)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  
  @override
  Future<Result<PersonResponse>> getPerson(String personId)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  
  @override
  Future<Result<PersonResponse>> findPersonByCpf(String cpf)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  
  @override
  Future<Result<StandardResponse<List<PersonResponse>>>> fetchPeople({String? cpf, String? cursor, int? limit, String? name}) async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  
  @override
  Future<Result<void>> deactivatePerson(String personId)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  
  @override
  Future<Result<void>> reactivatePerson(String personId)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  
  @override
  Future<Result<void>> requestPasswordReset(String personId)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  
  @override
  Future<Result<void>> assignRole(String personId, AssignRoleRequest request)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  
  @override
  Future<Result<List<PersonRoleResponse>>> listPersonRoles(String personId, {bool? active}) async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  
  @override
  Future<Result<List<PersonRoleResponse>>> queryRoles({bool active = true, String? role, required String system}) async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  
  @override
  Future<Result<void>> deactivateRole({required String personId, required String roleId}) async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  
  @override
  Future<Result<void>> reactivateRole({required String personId, required String roleId}) async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));

  // Registry additions
  @override
  Future<Result<void>> dischargePatient(String patientId, DischargePatientRequest request)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  
  @override
  Future<Result<void>> readmitPatient(String patientId, ReadmitPatientRequest request)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  
  @override
  Future<Result<void>> admitPatient(String patientId)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  
  @override
  Future<Result<void>> withdrawPatient(String patientId, WithdrawPatientRequest request)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented locally', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));


  @override
  Future<Result<StandardIdResponse>> createLookupItem(String tableName, Map<String, dynamic> request)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  @override
  Future<Result<void>> updateLookupItem(String tableName, String id, Map<String, dynamic> request)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  @override
  Future<Result<void>> toggleLookupItem(String tableName, String id, bool activate)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  @override
  Future<Result<StandardResponse<List<Map<String, dynamic>>>>> getLookupRequests()  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  @override
  Future<Result<StandardIdResponse>> createLookupRequest(Map<String, dynamic> request)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  @override
  Future<Result<void>> approveLookupRequest(String requestId)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  @override
  Future<Result<void>> rejectLookupRequest(String requestId)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));
  @override
  Future<Result<StandardResponse<PatientResponse>>> fetchPatientEnriched(String patientId)  async => Failure(AppError(code: 'LOCAL-400', message: 'Not implemented', kind: 'unexpected', module: 'storage', observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error)));

}
