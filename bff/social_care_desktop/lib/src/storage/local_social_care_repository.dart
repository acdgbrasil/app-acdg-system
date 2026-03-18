import 'dart:convert';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:persistence/persistence.dart';
import 'package:isar/isar.dart';

/// Implementation of [SocialCareContract] that uses Isar for local storage
/// and enqueues actions for synchronization.
class LocalSocialCareRepository implements SocialCareContract {
  final IsarService _isarService;
  final SyncQueueService _queueService;

  LocalSocialCareRepository({
    required IsarService isarService,
    required SyncQueueService queueService,
  })  : _isarService = isarService,
        _queueService = queueService;

  // ==========================================
  // HELPERS
  // ==========================================

  Future<Result<Patient>> _mutatePatient(
    PatientId patientId,
    String actionType,
    Map<String, dynamic> actionPayload,
    Patient Function(Patient) mutator,
  ) async {
    try {
      final cached = await _isarService.db.cachedPatients
          .filter()
          .patientIdEqualTo(patientId.value)
          .findFirst();

      if (cached == null) {
        return Failure(AppError(
          code: 'LOC-404',
          message: 'Patient not found in local cache',
          module: 'social-care/local-repo',
          kind: 'notFound',
          observability: const Observability(
            category: ErrorCategory.domainRuleViolation,
            severity: ErrorSeverity.warning,
          ),
        ));
      }

      final currentJson = jsonDecode(cached.fullRecordJson) as Map<String, dynamic>;
      final patient = PatientMapper.fromJson(currentJson);

      // Apply mutation
      final updatedPatient = mutator(patient);

      // Update local cache
      cached.fullRecordJson = jsonEncode(PatientMapper.toJson(updatedPatient));
      cached.version++;
      cached.isDirty = true;
      cached.lastSyncAt = DateTime.now().toUtc();

      await _isarService.db.writeTxn(() async {
        await _isarService.db.cachedPatients.put(cached);
      });

      // Enqueue sync action
      await _queueService.enqueue(
        patientId: patientId.value,
        actionType: actionType,
        payload: actionPayload,
      );

      return Success(updatedPatient);
    } catch (e) {
      return Failure(e);
    }
  }

  // ==========================================
  // CACHE MANAGEMENT (Internal/OfflineFirst)
  // ==========================================

  /// Updates the local cache without enqueuing a sync action.
  /// Used by OfflineFirstRepository when fresh data comes from remote.
  Future<void> updateCache(Patient patient) async {
    final fullJson = PatientMapper.toJson(patient);
    final cached = CachedPatient()
      ..patientId = patient.id.value
      ..personId = patient.personId.value
      ..firstName = patient.personalData?.firstName ?? ''
      ..lastName = patient.personalData?.lastName ?? ''
      ..cpf = patient.civilDocuments?.cpf?.value ?? ''
      ..fullRecordJson = jsonEncode(fullJson)
      ..version = patient.version
      ..isDirty = false // Data from remote is clean
      ..lastSyncAt = DateTime.now().toUtc();

    await _isarService.db.writeTxn(() async {
      await _isarService.db.cachedPatients.put(cached);
    });
  }

  /// Updates a lookup table cache.
  Future<void> updateLookupCache(String tableName, List<LookupItem> items) async {
    final cached = CachedLookup()
      ..tableName = tableName
      ..itemsJson = jsonEncode(items.map((i) => {
        'id': i.id,
        'codigo': i.codigo,
        'descricao': i.descricao,
      }).toList())
      ..lastFetchedAt = DateTime.now().toUtc();

    await _isarService.db.writeTxn(() async {
      await _isarService.db.cachedLookups.put(cached);
    });
  }

  // ==========================================
  // HEALTH
  // ==========================================

  @override
  Future<Result<void>> checkHealth() async => const Success(null);

  @override
  Future<Result<void>> checkReady() async {
    return Success(_isarService.db.isOpen);
  }

  // ==========================================
  // REGISTRY
  // ==========================================

  @override
  Future<Result<PatientId>> registerPatient(Patient patient) async {
    try {
      final fullJson = PatientMapper.toJson(patient);

      final cached = CachedPatient()
        ..patientId = patient.id.value
        ..personId = patient.personId.value
        ..firstName = patient.personalData?.firstName ?? ''
        ..lastName = patient.personalData?.lastName ?? ''
        ..cpf = patient.civilDocuments?.cpf?.value ?? ''
        ..fullRecordJson = jsonEncode(fullJson)
        ..version = patient.version
        ..isDirty = true
        ..lastSyncAt = DateTime.now().toUtc();

      await _isarService.db.writeTxn(() async {
        await _isarService.db.cachedPatients.put(cached);
      });

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
  Future<Result<Patient>> getPatient(PatientId id) async {
    try {
      final cached = await _isarService.db.cachedPatients
          .filter()
          .patientIdEqualTo(id.value)
          .findFirst();

      return switch (cached) {
        null => Failure(AppError(
            code: 'LOC-404',
            message: 'Patient not found in local cache',
            module: 'social-care/local-repo',
            kind: 'notFound',
            observability: const Observability(
              category: ErrorCategory.domainRuleViolation,
              severity: ErrorSeverity.warning,
            ),
          )),
        CachedPatient(:final fullRecordJson) => 
          Success(PatientMapper.fromJson(jsonDecode(fullRecordJson) as Map<String, dynamic>)),
      };
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<Patient>> getPatientByPersonId(PersonId personId) async {
    try {
      final cached = await _isarService.db.cachedPatients
          .filter()
          .personIdEqualTo(personId.value)
          .findFirst();

      return switch (cached) {
        null => Failure(AppError(
            code: 'LOC-404',
            message: 'Patient not found in local cache by personId',
            module: 'social-care/local-repo',
            kind: 'notFound',
            observability: const Observability(
              category: ErrorCategory.domainRuleViolation,
              severity: ErrorSeverity.warning,
            ),
          )),
        CachedPatient(:final fullRecordJson) => 
          Success(PatientMapper.fromJson(jsonDecode(fullRecordJson) as Map<String, dynamic>)),
      };
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
        'member': PatientMapper.familyMemberToJson(member),
        'prRelationshipId': prRelationshipId.value,
      },
      (p) => p.copyWith(
        familyMembers: [...p.familyMembers, member],
      ),
    );
    
    return switch (result) {
      Success() => const Success(null),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<void>> removeFamilyMember(PatientId patientId, PersonId memberId) async {
    final result = await _mutatePatient(
      patientId,
      'REMOVE_FAMILY_MEMBER',
      {
        'patientId': patientId.value,
        'memberId': memberId.value,
      },
      (p) => p.copyWith(
        familyMembers: p.familyMembers.where((m) => m.personId != memberId).toList(),
      ),
    );
    
    return switch (result) {
      Success() => const Success(null),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<void>> assignPrimaryCaregiver(PatientId patientId, PersonId memberId) async {
    final result = await _mutatePatient(
      patientId,
      'ASSIGN_CAREGIVER',
      {
        'patientId': patientId.value,
        'memberId': memberId.value,
      },
      (p) => p.copyWith(
        familyMembers: p.familyMembers.map((m) {
          if (m.personId == memberId) {
            return m.copyWith(isPrimaryCaregiver: true);
          }
          return m.copyWith(isPrimaryCaregiver: false);
        }).toList(),
      ),
    );
    
    return switch (result) {
      Success() => const Success(null),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<void>> updateSocialIdentity(PatientId patientId, SocialIdentity identity) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_SOCIAL_IDENTITY',
      {
        'patientId': patientId.value,
        'identity': PatientMapper.socialIdentityToJson(identity),
      },
      (p) => p.copyWith(socialIdentity: () => identity),
    );
    
    return switch (result) {
      Success() => const Success(null),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<List<AuditEvent>>> getAuditTrail(PatientId patientId, {String? eventType}) async {
    return const Success([]);
  }

  // ==========================================
  // ASSESSMENT
  // ==========================================

  @override
  Future<Result<void>> updateHousingCondition(PatientId patientId, HousingCondition condition) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_HOUSING',
      PatientMapper.housingConditionToJson(condition),
      (p) => p.copyWith(housingCondition: () => condition),
    );
    
    return switch (result) {
      Success() => const Success(null),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<void>> updateSocioEconomicSituation(PatientId patientId, SocioEconomicSituation situation) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_SOCIOECONOMIC',
      PatientMapper.socioEconomicToJson(situation),
      (p) => p.copyWith(socioeconomicSituation: () => situation),
    );
    
    return switch (result) {
      Success() => const Success(null),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<void>> updateWorkAndIncome(PatientId patientId, WorkAndIncome data) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_WORK_INCOME',
      PatientMapper.workAndIncomeToJson(data),
      (p) => p.copyWith(workAndIncome: () => data),
    );
    
    return switch (result) {
      Success() => const Success(null),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<void>> updateEducationalStatus(PatientId patientId, EducationalStatus status) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_EDUCATION',
      PatientMapper.educationalStatusToJson(status),
      (p) => p.copyWith(educationalStatus: () => status),
    );
    
    return switch (result) {
      Success() => const Success(null),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<void>> updateHealthStatus(PatientId patientId, HealthStatus status) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_HEALTH',
      PatientMapper.healthStatusToJson(status),
      (p) => p.copyWith(healthStatus: () => status),
    );
    
    return switch (result) {
      Success() => const Success(null),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<void>> updateCommunitySupportNetwork(PatientId patientId, CommunitySupportNetwork network) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_COMMUNITY_SUPPORT',
      PatientMapper.communitySupportToJson(network),
      (p) => p.copyWith(communitySupportNetwork: () => network),
    );
    
    return switch (result) {
      Success() => const Success(null),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<void>> updateSocialHealthSummary(PatientId patientId, SocialHealthSummary summary) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_SOCIAL_HEALTH',
      PatientMapper.socialHealthSummaryToJson(summary),
      (p) => p.copyWith(socialHealthSummary: () => summary),
    );
    
    return switch (result) {
      Success() => const Success(null),
      Failure(:final error) => Failure(error),
    };
  }

  // ==========================================
  // CARE
  // ==========================================

  @override
  Future<Result<AppointmentId>> registerAppointment(PatientId patientId, SocialCareAppointment appointment) async {
    final result = await _mutatePatient(
      patientId,
      'REGISTER_APPOINTMENT',
      {
        'patientId': patientId.value,
        'appointment': PatientMapper.appointmentToJson(appointment),
      },
      (p) => p.copyWith(
        appointments: [...p.appointments, appointment],
      ),
    );
    
    return switch (result) {
      Success() => Success(appointment.id),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<void>> updateIntakeInfo(PatientId patientId, IngressInfo info) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_INTAKE',
      {
        'patientId': patientId.value,
        'info': PatientMapper.intakeInfoToJson(info),
      },
      (p) => p.copyWith(intakeInfo: () => info),
    );
    
    return switch (result) {
      Success() => const Success(null),
      Failure(:final error) => Failure(error),
    };
  }

  // ==========================================
  // PROTECTION
  // ==========================================

  @override
  Future<Result<void>> updatePlacementHistory(PatientId patientId, PlacementHistory history) async {
    final result = await _mutatePatient(
      patientId,
      'UPDATE_PLACEMENT',
      PatientMapper.placementHistoryToJson(history),
      (p) => p.copyWith(placementHistory: () => history),
    );
    
    return switch (result) {
      Success() => const Success(null),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<ViolationReportId>> reportViolation(PatientId patientId, RightsViolationReport report) async {
    final result = await _mutatePatient(
      patientId,
      'REPORT_VIOLATION',
      {
        'patientId': patientId.value,
        'report': PatientMapper.violationReportToJson(report),
      },
      (p) => p.copyWith(
        violationReports: [...p.violationReports, report],
      ),
    );
    
    return switch (result) {
      Success() => Success(report.id),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<ReferralId>> createReferral(PatientId patientId, Referral referral) async {
    final result = await _mutatePatient(
      patientId,
      'CREATE_REFERRAL',
      {
        'patientId': patientId.value,
        'referral': PatientMapper.referralToJson(referral),
      },
      (p) => p.copyWith(
        referrals: [...p.referrals, referral],
      ),
    );
    
    return switch (result) {
      Success() => Success(referral.id),
      Failure(:final error) => Failure(error),
    };
  }

  // ==========================================
  // LOOKUP
  // ==========================================

  @override
  Future<Result<List<LookupItem>>> getLookupTable(String tableName) async {
    try {
      final cached = await _isarService.db.cachedLookups
          .filter()
          .tableNameEqualTo(tableName)
          .findFirst();

      return switch (cached) {
        null => const Success([]),
        CachedLookup(:final itemsJson) => (() {
            final List<dynamic> list = jsonDecode(itemsJson);
            return Success(list.map((item) {
              final map = item as Map<String, dynamic>;
              return LookupItem(
                id: map['id'],
                codigo: map['codigo'],
                descricao: map['descricao'],
              );
            }).toList());
          })(),
      };
    } catch (e) {
      return Failure(e);
    }
  }
}
