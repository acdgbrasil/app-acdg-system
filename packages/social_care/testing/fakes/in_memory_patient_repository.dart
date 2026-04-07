import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';
import 'package:social_care/src/ui/home/models/patient_summary.dart';

/// In-memory [PatientRepository] for testing.
///
/// Stores patients in a simple map, providing predictable behavior
/// without requiring any infrastructure dependency.
class InMemoryPatientRepository implements PatientRepository {
  final Map<String, Patient> _store = {};

  /// All patients currently stored.
  List<Patient> get patients => _store.values.toList();

  /// Clears all stored patients.
  void clear() => _store.clear();

  @override
  Future<Result<List<PatientSummary>>> listPatients() async {
    return Success(
      _store.values.map((p) {
        final firstName = p.personalData?.firstName ?? '';
        final lastName = p.personalData?.lastName ?? '';
        return PatientSummary(
          patientId: p.id.value,
          firstName: firstName,
          lastName: lastName,
          fullName: '$firstName $lastName'.trim(),
          primaryDiagnosis: p.diagnoses.isNotEmpty
              ? p.diagnoses.first.description
              : null,
          memberCount: p.familyMembers.length,
        );
      }).toList(),
    );
  }

  @override
  Future<Result<PatientId>> registerPatient(Patient patient) async {
    _store[patient.id.value] = patient;
    return Success(patient.id);
  }

  @override
  Future<Result<Patient>> getPatient(PatientId id) async {
    final patient = _store[id.value];
    if (patient == null) {
      return Failure(
        AppError(
          code: 'PAT-404',
          message: 'Patient not found: ${id.value}',
          module: 'social-care/test',
          kind: 'notFound',
          http: 404,
          observability: const Observability(
            category: ErrorCategory.domainRuleViolation,
            severity: ErrorSeverity.warning,
          ),
        ),
      );
    }

    return Success(patient);
  }

  @override
  Future<Result<Patient>> getPatientByPersonId(PersonId personId) async {
    try {
      final patient = _store.values.firstWhere((p) => p.personId == personId);
      return Success(patient);
    } catch (_) {
      return Failure(
        AppError(
          code: 'PAT-404',
          message: 'Patient not found for person: ${personId.value}',
          module: 'social-care/test',
          kind: 'notFound',
          http: 404,
          observability: const Observability(
            category: ErrorCategory.domainRuleViolation,
            severity: ErrorSeverity.warning,
          ),
        ),
      );
    }
  }

  @override
  Future<Result<void>> addFamilyMember(
    PatientId patientId,
    FamilyMember member,
    LookupId prRelationshipId) async {
    final patient = _store[patientId.value];
    if (patient == null) {
      return Failure(
        AppError(
          code: '404',
          message: 'Not Found',
          module: 'test',
          kind: 'notFound',
          http: 404,
          observability: const Observability(
            category: ErrorCategory.infrastructureDependencyFailure,
            severity: ErrorSeverity.error,
          ),
        ),
      );
    }
    _store[patientId.value] = patient.copyWith(
      familyMembers: [...patient.familyMembers, member],
    );
    return const Success(null);
  }

  @override
  Future<Result<void>> removeFamilyMember(
    PatientId patientId,
    PersonId memberId,
  ) async {
    final patient = _store[patientId.value];
    if (patient == null) {
      return Failure(
        AppError(
          code: '404',
          message: 'Not Found',
          module: 'test',
          kind: 'notFound',
          http: 404,
          observability: const Observability(
            category: ErrorCategory.infrastructureDependencyFailure,
            severity: ErrorSeverity.error,
          ),
        ),
      );
    }
    final newList = patient.familyMembers
        .where((m) => m.personId != memberId)
        .toList();
    _store[patientId.value] = patient.copyWith(familyMembers: newList);
    return const Success(null);
  }

  @override
  Future<Result<void>> assignPrimaryCaregiver(
    PatientId patientId,
    PersonId memberId,
  ) async {
    return const Success(null);
  }

  @override
  Future<Result<void>> updateSocialIdentity(
    PatientId patientId,
    SocialIdentity identity,
  ) async {
    final patient = _store[patientId.value];
    if (patient == null) {
      return Failure(
        AppError(
          code: '404',
          message: 'Not Found',
          module: 'test',
          kind: 'notFound',
          http: 404,
          observability: const Observability(
            category: ErrorCategory.infrastructureDependencyFailure,
            severity: ErrorSeverity.error,
          ),
        ),
      );
    }
    _store[patientId.value] = patient.copyWith(socialIdentity: () => identity);
    return const Success(null);
  }

  @override
  Future<Result<List<AuditEvent>>> getAuditTrail(
    PatientId patientId, {
    String? eventType,
  }) async {
    return const Success([]);
  }

  @override
  Future<Result<void>> updateHousingCondition(
    PatientId patientId,
    HousingCondition condition,
  ) async {
    final patient = _store[patientId.value];
    if (patient == null) {
      return Failure(
        AppError(
          code: '404',
          message: 'Not Found',
          module: 'test',
          kind: 'notFound',
          http: 404,
          observability: const Observability(
            category: ErrorCategory.infrastructureDependencyFailure,
            severity: ErrorSeverity.error,
          ),
        ),
      );
    }
    _store[patientId.value] = patient.copyWith(
      housingCondition: () => condition,
    );
    return const Success(null);
  }

  @override
  Future<Result<void>> updateSocioEconomicSituation(
    PatientId patientId,
    SocioEconomicSituation situation,
  ) async {
    final patient = _store[patientId.value];
    if (patient == null) {
      return Failure(
        AppError(
          code: '404',
          message: 'Not Found',
          module: 'test',
          kind: 'notFound',
          http: 404,
          observability: const Observability(
            category: ErrorCategory.infrastructureDependencyFailure,
            severity: ErrorSeverity.error,
          ),
        ),
      );
    }
    _store[patientId.value] = patient.copyWith(
      socioeconomicSituation: () => situation,
    );
    return const Success(null);
  }

  @override
  Future<Result<void>> updateWorkAndIncome(
    PatientId patientId,
    WorkAndIncome data,
  ) async {
    final patient = _store[patientId.value];
    if (patient == null) {
      return Failure(
        AppError(
          code: '404',
          message: 'Not Found',
          module: 'test',
          kind: 'notFound',
          http: 404,
          observability: const Observability(
            category: ErrorCategory.infrastructureDependencyFailure,
            severity: ErrorSeverity.error,
          ),
        ),
      );
    }
    _store[patientId.value] = patient.copyWith(workAndIncome: () => data);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateEducationalStatus(
    PatientId patientId,
    EducationalStatus status,
  ) async {
    final patient = _store[patientId.value];
    if (patient == null) {
      return Failure(
        AppError(
          code: '404',
          message: 'Not Found',
          module: 'test',
          kind: 'notFound',
          http: 404,
          observability: const Observability(
            category: ErrorCategory.infrastructureDependencyFailure,
            severity: ErrorSeverity.error,
          ),
        ),
      );
    }
    _store[patientId.value] = patient.copyWith(educationalStatus: () => status);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateHealthStatus(
    PatientId patientId,
    HealthStatus status,
  ) async {
    final patient = _store[patientId.value];
    if (patient == null) {
      return Failure(
        AppError(
          code: '404',
          message: 'Not Found',
          module: 'test',
          kind: 'notFound',
          http: 404,
          observability: const Observability(
            category: ErrorCategory.infrastructureDependencyFailure,
            severity: ErrorSeverity.error,
          ),
        ),
      );
    }
    _store[patientId.value] = patient.copyWith(healthStatus: () => status);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateCommunitySupportNetwork(
    PatientId patientId,
    CommunitySupportNetwork network,
  ) async {
    final patient = _store[patientId.value];
    if (patient == null) {
      return Failure(
        AppError(
          code: '404',
          message: 'Not Found',
          module: 'test',
          kind: 'notFound',
          http: 404,
          observability: const Observability(
            category: ErrorCategory.infrastructureDependencyFailure,
            severity: ErrorSeverity.error,
          ),
        ),
      );
    }
    _store[patientId.value] = patient.copyWith(
      communitySupportNetwork: () => network,
    );
    return const Success(null);
  }

  @override
  Future<Result<void>> updateSocialHealthSummary(
    PatientId patientId,
    SocialHealthSummary summary,
  ) async {
    final patient = _store[patientId.value];
    if (patient == null) {
      return Failure(
        AppError(
          code: '404',
          message: 'Not Found',
          module: 'test',
          kind: 'notFound',
          http: 404,
          observability: const Observability(
            category: ErrorCategory.infrastructureDependencyFailure,
            severity: ErrorSeverity.error,
          ),
        ),
      );
    }
    _store[patientId.value] = patient.copyWith(
      socialHealthSummary: () => summary,
    );
    return const Success(null);
  }

  @override
  Future<Result<AppointmentId>> registerAppointment(
    PatientId patientId,
    SocialCareAppointment appointment,
  ) async {
    return Success(appointment.id);
  }

  @override
  Future<Result<void>> updateIntakeInfo(
    PatientId patientId,
    IngressInfo info,
  ) async {
    final patient = _store[patientId.value];
    if (patient == null) {
      return Failure(
        AppError(
          code: '404',
          message: 'Not Found',
          module: 'test',
          kind: 'notFound',
          http: 404,
          observability: const Observability(
            category: ErrorCategory.infrastructureDependencyFailure,
            severity: ErrorSeverity.error,
          ),
        ),
      );
    }
    _store[patientId.value] = patient.copyWith(intakeInfo: () => info);
    return const Success(null);
  }

  @override
  Future<Result<void>> updatePlacementHistory(
    PatientId patientId,
    PlacementHistory history,
  ) async {
    final patient = _store[patientId.value];
    if (patient == null) {
      return Failure(
        AppError(
          code: '404',
          message: 'Not Found',
          module: 'test',
          kind: 'notFound',
          http: 404,
          observability: const Observability(
            category: ErrorCategory.infrastructureDependencyFailure,
            severity: ErrorSeverity.error,
          ),
        ),
      );
    }
    _store[patientId.value] = patient.copyWith(placementHistory: () => history);
    return const Success(null);
  }

  @override
  Future<Result<ViolationReportId>> reportViolation(
    PatientId patientId,
    RightsViolationReport report,
  ) async {
    return Success(report.id);
  }

  @override
  Future<Result<ReferralId>> createReferral(
    PatientId patientId,
    Referral referral,
  ) async {
    return Success(referral.id);
  }

}
