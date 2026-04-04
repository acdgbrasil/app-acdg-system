import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:core/core.dart';
import 'package:drift/drift.dart';
import 'package:persistence/persistence.dart';
import 'package:shared/shared.dart';

/// Implementation of [SocialCareContract] that uses Drift for local storage
/// and enqueues actions for synchronization.
class LocalSocialCareRepository implements SocialCareContract {
  final DriftDatabaseService _dbService;
  final SyncQueueService _queueService;

  LocalSocialCareRepository({
    required DriftDatabaseService dbService,
    required SyncQueueService queueService,
  })  : _dbService = dbService,
        _queueService = queueService;

  AcdgDatabase get _db => _dbService.db;

  // ==========================================
  // HELPERS
  // ==========================================

  Future<Result<Patient>> _mutatePatient(
    PatientId patientId,
    String actionType,
    Map<String, dynamic> actionPayload,
    Patient Function(Patient) mutator,
  ) async {
    debugPrint('[Local Repo] _mutatePatient: $actionType for ${patientId.value}');
    try {
      final cached = await (_db.select(_db.cachedPatients)
            ..where((t) => t.patientId.equals(patientId.value)))
          .getSingleOrNull();

      if (cached == null) {
        debugPrint('[Local Repo] Patient NOT FOUND in cache.');
        return Failure(_notFoundError('Patient not found in local cache'));
      }

      final currentJson =
          jsonDecode(cached.fullRecordJson) as Map<String, dynamic>;
      final Patient patient;
      switch (PatientTranslator.fromJson(currentJson)) {
        case Success(:final value): 
          debugPrint('[Local Repo] Patient decoded from cache.');
          patient = value;
        case Failure(:final error): 
          debugPrint('[Local Repo] FAILED to decode patient: $error');
          return Failure(error);
      }
      final updatedPatient = mutator(patient);

      debugPrint('[Local Repo] Updating Drift record...');
      await (_db.update(_db.cachedPatients)
            ..where((t) => t.patientId.equals(patientId.value)))
          .write(
        CachedPatientsCompanion(
          fullRecordJson:
              Value(jsonEncode(PatientTranslator.toJson(updatedPatient))),
          version: Value(cached.version + 1),
          isDirty: const Value(true),
          lastSyncAt: Value(DateTime.now().toUtc()),
        ),
      );

      debugPrint('[Local Repo] Enqueueing sync action: $actionType');
      debugPrint('[Local Repo] Payload: $actionPayload');
      await _queueService.enqueue(
        patientId: patientId.value,
        actionType: actionType,
        payload: actionPayload,
      );
      debugPrint('[Local Repo] Mutation and Queue COMPLETE.');

      return Success(updatedPatient);
    } catch (e) {
      debugPrint('[Local Repo] CRITICAL ERROR in _mutatePatient: $e');
      return Failure(AppError(
        code: 'LOC-500',
        message: 'Failed to mutate patient locally: $e',
        module: 'social-care/local-repo',
        kind: 'infrastructure',
        observability: const Observability(
          category: ErrorCategory.infrastructureDependencyFailure,
          severity: ErrorSeverity.error,
        ),
      ));
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

    await _db.into(_db.cachedPatients).insert(
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
  Future<void> updateLookupCache(
    String tableName,
    List<LookupItem> items,
  ) async {
    final itemsJson = jsonEncode(
      items
          .map((i) =>
              {'id': i.id, 'codigo': i.codigo, 'descricao': i.descricao})
          .toList(),
    );

    await _db.into(_db.cachedLookups).insert(
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
  Future<void> updateCacheFromSummaries(
      List<PatientOverview> summaries) async {
    final existingPatients = await _db.select(_db.cachedPatients).get();
    final existingMap = {
      for (final c in existingPatients) c.patientId: c,
    };

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
            firstName: Value(item.firstName ?? ''),
            lastName: Value(item.lastName ?? ''),
            cpf: Value(existing?.cpf ?? ''),
            fullRecordJson: shouldPreserveRecord
                ? existing!.fullRecordJson
                : jsonEncode(item.toJson()),
            version: Value(existing?.version ?? 0),
            isDirty: Value(existing?.isDirty ?? false),
            lastSyncAt: DateTime.now().toUtc(),
          ),
          onConflict: DoUpdate(
            (old) => CachedPatientsCompanion(
              personId: Value(item.personId.isNotEmpty
                  ? item.personId
                  : existing?.personId ?? ''),
              firstName: Value(item.firstName ?? ''),
              lastName: Value(item.lastName ?? ''),
              fullRecordJson: shouldPreserveRecord
                  ? Value(existing!.fullRecordJson)
                  : Value(jsonEncode(item.toJson())),
              lastSyncAt: Value(DateTime.now().toUtc()),
            ),
          ),
        );
      }
    });
  }

  /// Checks whether there are pending sync actions for a given patient.
  Future<bool> hasPendingActions(PatientId patientId) async {
    final actions = await _queueService.getPendingActions();
    return actions.any((a) => a.patientId == patientId.value);
  }

  /// Updates the local cache from a [PatientRemote] without enqueuing a sync action.
  Future<void> updateCacheFromRemote(PatientRemote dto) async {
    final fullJson = dto.toJson();
    final pd = dto.personalData;

    await _db.into(_db.cachedPatients).insert(
          CachedPatientsCompanion.insert(
            patientId: dto.patientId,
            personId: dto.personId,
            firstName: Value(pd?['firstName'] as String? ?? ''),
            lastName: Value(pd?['lastName'] as String? ?? ''),
            cpf: Value(''),
            fullRecordJson: jsonEncode(fullJson),
            version: Value(dto.version),
            isDirty: const Value(false),
            lastSyncAt: DateTime.now().toUtc(),
          ),
          onConflict: DoUpdate(
            (old) => CachedPatientsCompanion(
              personId: Value(dto.personId),
              firstName: Value(pd?['firstName'] as String? ?? ''),
              lastName: Value(pd?['lastName'] as String? ?? ''),
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
  Future<Result<List<PatientOverview>>> fetchPatients() async {
    try {
      final allCached = await _db.select(_db.cachedPatients).get();
      final summaries = allCached.map(_toSummaryDTO).toList();
      return Success(summaries);
    } catch (e) {
      return Failure(e);
    }
  }

  PatientOverview _toSummaryDTO(CachedPatient c) {
    try {
      final json = jsonDecode(c.fullRecordJson) as Map<String, dynamic>;

      if (json.containsKey('prRelationshipId')) {
        final pd = json['personalData'] as Map<String, dynamic>?;
        final diagnoses = (json['diagnoses'] as List?) ??
            (json['initialDiagnoses'] as List?) ??
            [];
        final members = (json['familyMembers'] as List?) ?? [];
        final firstName = pd?['firstName'] as String? ?? c.firstName;
        final lastName = pd?['lastName'] as String? ?? c.lastName;

        return PatientOverview(
          patientId: json['patientId'] as String? ?? c.patientId,
          personId: json['personId'] as String? ?? c.personId,
          firstName: firstName,
          lastName: lastName,
          fullName: '$firstName $lastName'.trim(),
          primaryDiagnosis: diagnoses.isNotEmpty
              ? (diagnoses.first as Map<String, dynamic>)['description']
                  as String?
              : null,
          memberCount: members.length,
        );
      }

      return PatientOverview.fromJson(json);
    } catch (_) {
      return PatientOverview(
        patientId: c.patientId,
        personId: c.personId,
        firstName: c.firstName.isEmpty ? null : c.firstName,
        lastName: c.lastName.isEmpty ? null : c.lastName,
        fullName: '${c.firstName} ${c.lastName}'.trim(),
        memberCount: 0,
      );
    }
  }

  @override
  Future<Result<PatientId>> registerPatient(Patient patient) async {
    try {
      final fullJson = PatientTranslator.toJson(patient);

      await _db.into(_db.cachedPatients).insert(
            CachedPatientsCompanion.insert(
              patientId: patient.id.value,
              personId: patient.personId.value,
              firstName: Value(patient.personalData?.firstName ?? ''),
              lastName: Value(patient.personalData?.lastName ?? ''),
              cpf: Value(patient.civilDocuments?.cpf?.value ?? ''),
              fullRecordJson: jsonEncode(fullJson),
              version: Value(patient.version),
              isDirty: const Value(true),
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
                isDirty: const Value(true),
                lastSyncAt: Value(DateTime.now().toUtc()),
              ),
              target: [_db.cachedPatients.patientId],
            ),
          );

      await _queueService.enqueue(
        patientId: patient.id.value,
        actionType: 'REGISTER_PATIENT',
        payload: fullJson,
      );

      return Success(patient.id);
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<PatientRemote>> fetchPatient(PatientId id) async {
    try {
      final cached = await (_db.select(_db.cachedPatients)
            ..where((t) => t.patientId.equals(id.value)))
          .getSingleOrNull();

      if (cached == null) {
        return Failure(_notFoundError('Patient not found in local cache'));
      }

      final json = jsonDecode(cached.fullRecordJson) as Map<String, dynamic>;
      return Success(PatientRemote.fromJson(json));
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<PatientRemote>> fetchPatientByPersonId(PersonId personId) async {
    try {
      final cached = await (_db.select(_db.cachedPatients)
            ..where((t) => t.personId.equals(personId.value)))
          .getSingleOrNull();

      if (cached == null) {
        return Failure(
            _notFoundError('Patient not found in local cache by personId'));
      }

      final json = jsonDecode(cached.fullRecordJson) as Map<String, dynamic>;
      return Success(PatientRemote.fromJson(json));
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> addFamilyMember(
    PatientId patientId,
    FamilyMember member,
    LookupId prRelationshipId,
  ) async {
    final result = await _mutatePatient(
      patientId,
      'ADD_FAMILY_MEMBER',
      {
        'patientId': patientId.value,
        'member': PatientTranslator.familyMemberToJson(member),
        'prRelationshipId': prRelationshipId.value,
      },
      (p) => p.copyWith(familyMembers: [...p.familyMembers, member]),
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> removeFamilyMember(
    PatientId patientId,
    PersonId memberId,
  ) async {
    final result = await _mutatePatient(
      patientId,
      'REMOVE_FAMILY_MEMBER',
      {'patientId': patientId.value, 'memberId': memberId.value},
      (p) => p.copyWith(
        familyMembers:
            p.familyMembers.where((m) => m.personId != memberId).toList(),
      ),
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> assignPrimaryCaregiver(
    PatientId patientId,
    PersonId memberId,
  ) async {
    final result = await _mutatePatient(
      patientId,
      'ASSIGN_CAREGIVER',
      {'patientId': patientId.value, 'memberId': memberId.value},
      (p) => p.copyWith(
        familyMembers: p.familyMembers.map((m) {
          if (m.personId == memberId) {
            return m.copyWith(isPrimaryCaregiver: true);
          }
          return m.copyWith(isPrimaryCaregiver: false);
        }).toList(),
      ),
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateSocialIdentity(
    PatientId patientId,
    SocialIdentity identity,
  ) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_SOCIAL_IDENTITY',
      {
        'patientId': patientId.value,
        'identity': PatientTranslator.socialIdentityToJson(identity),
      },
      (p) => p.copyWith(socialIdentity: () => identity),
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<List<AuditEvent>>> getAuditTrail(
    PatientId patientId, {
    String? eventType,
  }) async {
    return const Success([]);
  }

  // ==========================================
  // ASSESSMENT
  // ==========================================

  @override
  Future<Result<void>> updateHousingCondition(
    PatientId patientId,
    HousingCondition condition,
  ) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_HOUSING',
      PatientTranslator.housingConditionToJson(condition),
      (p) => p.copyWith(housingCondition: () => condition),
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateSocioEconomicSituation(
    PatientId patientId,
    SocioEconomicSituation situation,
  ) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_SOCIOECONOMIC',
      PatientTranslator.socioEconomicToJson(situation),
      (p) => p.copyWith(socioeconomicSituation: () => situation),
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateWorkAndIncome(
    PatientId patientId,
    WorkAndIncome data,
  ) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_WORK_INCOME',
      PatientTranslator.workAndIncomeToJson(data),
      (p) => p.copyWith(workAndIncome: () => data),
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateEducationalStatus(
    PatientId patientId,
    EducationalStatus status,
  ) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_EDUCATION',
      PatientTranslator.educationalStatusToJson(status),
      (p) => p.copyWith(educationalStatus: () => status),
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateHealthStatus(
    PatientId patientId,
    HealthStatus status,
  ) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_HEALTH',
      PatientTranslator.healthStatusToJson(status),
      (p) => p.copyWith(healthStatus: () => status),
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateCommunitySupportNetwork(
    PatientId patientId,
    CommunitySupportNetwork network,
  ) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_COMMUNITY_SUPPORT',
      PatientTranslator.communitySupportToJson(network),
      (p) => p.copyWith(communitySupportNetwork: () => network),
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateSocialHealthSummary(
    PatientId patientId,
    SocialHealthSummary summary,
  ) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_SOCIAL_HEALTH',
      PatientTranslator.socialHealthSummaryToJson(summary),
      (p) => p.copyWith(socialHealthSummary: () => summary),
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  // ==========================================
  // CARE
  // ==========================================

  @override
  Future<Result<AppointmentId>> registerAppointment(
    PatientId patientId,
    SocialCareAppointment appointment,
  ) async {
    final result = await _mutatePatient(
      patientId,
      'REGISTER_APPOINTMENT',
      {
        'patientId': patientId.value,
        'appointment': PatientTranslator.appointmentToJson(appointment),
      },
      (p) => p.copyWith(appointments: [...p.appointments, appointment]),
    );

    if (result case Failure(:final error)) return Failure(error);
    return Success(appointment.id);
  }

  @override
  Future<Result<void>> updateIntakeInfo(
    PatientId patientId,
    IngressInfo info,
  ) async {
    final result = await _mutatePatient(patientId, 'UPDATE_INTAKE', {
      'patientId': patientId.value,
      'info': PatientTranslator.intakeInfoToJson(info),
    }, (p) => p.copyWith(intakeInfo: () => info));

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  // ==========================================
  // PROTECTION
  // ==========================================

  @override
  Future<Result<void>> updatePlacementHistory(
    PatientId patientId,
    PlacementHistory history,
  ) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_PLACEMENT',
      PatientTranslator.placementHistoryToJson(history),
      (p) => p.copyWith(placementHistory: () => history),
    );

    if (result case Failure(:final error)) return Failure(error);
    return const Success(null);
  }

  @override
  Future<Result<ViolationReportId>> reportViolation(
    PatientId patientId,
    RightsViolationReport report,
  ) async {
    final result = await _mutatePatient(
      patientId,
      'REPORT_VIOLATION',
      {
        'patientId': patientId.value,
        'report': PatientTranslator.violationReportToJson(report),
      },
      (p) => p.copyWith(violationReports: [...p.violationReports, report]),
    );

    if (result case Failure(:final error)) return Failure(error);
    return Success(report.id);
  }

  @override
  Future<Result<ReferralId>> createReferral(
    PatientId patientId,
    Referral referral,
  ) async {
    final result = await _mutatePatient(
      patientId,
      'CREATE_REFERRAL',
      {
        'patientId': patientId.value,
        'referral': PatientTranslator.referralToJson(referral),
      },
      (p) => p.copyWith(referrals: [...p.referrals, referral]),
    );

    if (result case Failure(:final error)) return Failure(error);
    return Success(referral.id);
  }

  // ==========================================
  // LOOKUP
  // ==========================================

  @override
  Future<Result<List<LookupItem>>> getLookupTable(String tableName) async {
    try {
      final cached = await (_db.select(_db.cachedLookups)
            ..where((t) => t.lookupName.equals(tableName)))
          .getSingleOrNull();

      if (cached == null) return const Success([]);

      final List<dynamic> list = jsonDecode(cached.itemsJson);
      return Success(
        list.map((item) {
          final map = item as Map<String, dynamic>;
          return LookupItem(
            id: map['id'],
            codigo: map['codigo'],
            descricao: map['descricao'],
          );
        }).toList(),
      );
    } catch (e) {
      return Failure(e);
    }
  }
}
