import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';
import 'package:social_care/src/ui/home/models/ficha_status.dart';
import 'package:social_care/src/ui/home/models/patient_detail.dart';
import 'package:social_care/src/ui/home/models/patient_detail_result.dart';
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
  Future<Result<PatientDetailResult>> getPatient(PatientId id) async {
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

    final detail = _toPatientDetail(patient);
    return Success(
      PatientDetailResult(
        patientDetail: detail,
        fichas: FichaStatus.fromDetail(detail),
      ),
    );
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
    LookupId prRelationshipId,
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

  // --- Internal Mapping (matches BffPatientRepository) ---

  PatientDetail _toPatientDetail(Patient patient) {
    final pd = patient.personalData;
    final docs = patient.civilDocuments;
    final addr = patient.address;
    final si = patient.socialIdentity;
    final ii = patient.intakeInfo;

    return PatientDetail(
      patientId: patient.id.value,
      personId: patient.personId.value,
      version: patient.version,
      familyMembers: patient.familyMembers
          .map(
            (m) => FamilyMemberDetail.fromJson({
              'id': m.personId.value,
              'relationshipId': m.relationshipId.value,
              'isPrimaryCaregiver': m.isPrimaryCaregiver,
              'residesWithPatient': m.residesWithPatient,
              'hasDisability': m.hasDisability,
              'birthDate': m.birthDate.date.toIso8601String(),
            }),
          )
          .toList(),
      diagnoses: patient.diagnoses
          .map(
            (d) => DiagnosisDetail.fromJson({
              'id': d.id.value,
              'description': d.description,
              'date': d.date.date.toIso8601String(),
            }),
          )
          .toList(),
      appointments: patient.appointments
          .map(
            (a) => AppointmentDetail.fromJson({
              'id': a.id.value,
              'date': a.date.date.toIso8601String(),
              'professionalInChargeId': a.professionalInChargeId.value,
              'type': a.type.name,
              'summary': a.summary,
              'actionPlan': a.actionPlan,
            }),
          )
          .toList(),
      referrals: patient.referrals
          .map((r) => ReferralDetail.fromJson({
                'id': r.id.value,
                'date': r.date.toIso8601(),
                'professionalId': r.requestingProfessionalId.value,
                'referredPersonId': r.referredPersonId.value,
                'destinationService': r.destinationService.name.toSnakeCaseUpper(),
                'reason': r.reason,
                'status': r.status.name.toSnakeCaseUpper(),
              }))
          .toList(),
      violationReports: patient.violationReports
          .map((v) => ViolationReportDetail.fromJson({
                'id': v.id.value,
                'reportDate': v.reportDate.toIso8601(),
                'incidentDate': v.incidentDate?.toIso8601(),
                'victimId': v.victimId.value,
                'violationType': v.violationType.name.toSnakeCaseUpper(),
                'violationTypeId': v.violationTypeId?.value,
                'descriptionOfFact': v.descriptionOfFact,
                'actionsTaken': v.actionsTaken,
              }))
          .toList(),
      computedAnalytics: _buildAnalytics(patient),
      personalData: pd != null
          ? PersonalDataDetail(
              firstName: pd.firstName,
              lastName: pd.lastName,
              motherName: pd.motherName,
              nationality: pd.nationality,
              sex: pd.sex.name,
              socialName: pd.socialName,
              birthDate: pd.birthDate.date.toIso8601String(),
              phone: pd.phone,
            )
          : null,
      civilDocuments: docs != null
          ? CivilDocumentsDetail(
              cpf: docs.cpf?.formatted,
              nis: docs.nis?.value,
              rgDocument: docs.rgDocument != null
                  ? RgDocumentDetail(
                      number: docs.rgDocument!.number,
                      issuingState: docs.rgDocument!.issuingState,
                      issuingAgency: docs.rgDocument!.issuingAgency,
                      issueDate:
                          docs.rgDocument!.issueDate.date.toIso8601String(),
                    )
                  : null,
            )
          : null,
      address: addr != null
          ? AddressDetail(
              cep: addr.cep?.formatted,
              isShelter: addr.isShelter,
              residenceLocation: addr.residenceLocation.name,
              street: addr.street,
              neighborhood: addr.neighborhood,
              number: addr.number,
              complement: addr.complement,
              state: addr.state,
              city: addr.city,
            )
          : null,
      socialIdentity: si != null
          ? SocialIdentityDetail(
              typeId: si.typeId.value,
              otherDescription: si.otherDescription,
            )
          : null,
      intakeInfo: ii != null
          ? IntakeInfoDetail(
              ingressTypeId: ii.ingressTypeId.value,
              originName: ii.originName,
              originContact: ii.originContact,
              serviceReason: ii.serviceReason,
              linkedSocialPrograms: ii.linkedSocialPrograms
                  .map(
                    (p) => LinkedProgramDetail(
                      programId: p.programId.value,
                      observation: p.observation,
                    ),
                  )
                  .toList(),
            )
          : null,
      housingCondition: patient.housingCondition != null
          ? HousingConditionDetail.fromJson({
              'type': patient.housingCondition!.type.name,
              'wallMaterial': patient.housingCondition!.wallMaterial.name,
              'waterSupply': patient.housingCondition!.waterSupply.name,
              'electricityAccess': patient.housingCondition!.electricityAccess.name,
              'sewageDisposal': patient.housingCondition!.sewageDisposal.name,
              'wasteCollection': patient.housingCondition!.wasteCollection.name,
              'accessibilityLevel': patient.housingCondition!.accessibilityLevel.name,
              'numberOfRooms': patient.housingCondition!.numberOfRooms,
              'numberOfBedrooms': patient.housingCondition!.numberOfBedrooms,
              'numberOfBathrooms': patient.housingCondition!.numberOfBathrooms,
              'hasPipedWater': patient.housingCondition!.hasPipedWater,
              'isInGeographicRiskArea': patient.housingCondition!.isInGeographicRiskArea,
              'hasDifficultAccess': patient.housingCondition!.hasDifficultAccess,
              'isInSocialConflictArea': patient.housingCondition!.isInSocialConflictArea,
              'hasDiagnosticObservations': patient.housingCondition!.hasDiagnosticObservations,
            })
          : null,
    );
  }

  ComputedAnalyticsDetail _buildAnalytics(Patient patient) {
    return const ComputedAnalyticsDetail(
      ageProfile: AgeProfileDetail(
        range0to6: 0,
        range7to14: 0,
        range15to17: 0,
        range18to29: 0,
        range30to59: 0,
        range60to64: 0,
        range65to69: 0,
        range70Plus: 0,
        totalMembers: 0,
      ),
    );
  }
}
