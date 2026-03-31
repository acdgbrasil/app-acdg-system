import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:social_care/src/data/model/patient_summary_api_model.dart';
import 'package:social_care/src/data/services/patient_service.dart';
import 'package:social_care/src/ui/home/models/ficha_status.dart';
import 'package:social_care/src/ui/home/models/patient_detail.dart';
import 'package:social_care/src/ui/home/models/patient_detail_result.dart';
import 'package:social_care/src/ui/home/models/patient_summary.dart';

import 'patient_repository.dart';

/// [PatientRepository] implementation backed by the Social Care BFF.
///
/// Uses [PatientService] for raw BFF calls, then maps API models
/// to typed domain/UI models.
class BffPatientRepository implements PatientRepository {
  BffPatientRepository({
    required SocialCareContract bff,
    required PatientService patientService,
  }) : _bff = bff,
       _patientService = patientService;

  final SocialCareContract _bff;
  final PatientService _patientService;

  @override
  Future<Result<List<PatientSummary>>> listPatients() async {
    final result = await _patientService.listPatients();

    return switch (result) {
      Success(:final value) => Success(
        value
            .map(PatientSummaryApiModel.fromJson)
            .map(
              (api) => PatientSummary(
                patientId: api.patientId,
                firstName: api.firstName,
                lastName: api.lastName,
                fullName: api.fullName ?? '${api.firstName} ${api.lastName}',
                primaryDiagnosis: api.primaryDiagnosis,
                memberCount: api.memberCount,
              ),
            )
            .toList(),
      ),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<PatientId>> registerPatient(Patient patient) {
    return _bff.registerPatient(patient);
  }

  @override
  Future<Result<PatientDetailResult>> getPatient(PatientId id) async {
    final result = await _patientService.getPatient(id);

    return switch (result) {
      Success(:final value) => Success(_toDetailResult(value)),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<Patient>> getPatientByPersonId(PersonId personId) {
    return _bff.getPatientByPersonId(personId);
  }

  @override
  Future<Result<void>> addFamilyMember(
    PatientId patientId,
    FamilyMember member,
    LookupId prRelationshipId,
  ) {
    return _bff.addFamilyMember(patientId, member, prRelationshipId);
  }

  @override
  Future<Result<void>> removeFamilyMember(
    PatientId patientId,
    PersonId memberId,
  ) {
    return _bff.removeFamilyMember(patientId, memberId);
  }

  @override
  Future<Result<void>> assignPrimaryCaregiver(
    PatientId patientId,
    PersonId memberId,
  ) {
    return _bff.assignPrimaryCaregiver(patientId, memberId);
  }

  @override
  Future<Result<void>> updateSocialIdentity(
    PatientId patientId,
    SocialIdentity identity,
  ) {
    return _bff.updateSocialIdentity(patientId, identity);
  }

  @override
  Future<Result<List<AuditEvent>>> getAuditTrail(
    PatientId patientId, {
    String? eventType,
  }) {
    return _bff.getAuditTrail(patientId, eventType: eventType);
  }

  @override
  Future<Result<void>> updateHousingCondition(
    PatientId patientId,
    HousingCondition condition,
  ) {
    return _bff.updateHousingCondition(patientId, condition);
  }

  @override
  Future<Result<void>> updateSocioEconomicSituation(
    PatientId patientId,
    SocioEconomicSituation situation,
  ) {
    return _bff.updateSocioEconomicSituation(patientId, situation);
  }

  @override
  Future<Result<void>> updateWorkAndIncome(
    PatientId patientId,
    WorkAndIncome data,
  ) {
    return _bff.updateWorkAndIncome(patientId, data);
  }

  @override
  Future<Result<void>> updateEducationalStatus(
    PatientId patientId,
    EducationalStatus status,
  ) {
    return _bff.updateEducationalStatus(patientId, status);
  }

  @override
  Future<Result<void>> updateHealthStatus(
    PatientId patientId,
    HealthStatus status,
  ) {
    return _bff.updateHealthStatus(patientId, status);
  }

  @override
  Future<Result<void>> updateCommunitySupportNetwork(
    PatientId patientId,
    CommunitySupportNetwork network,
  ) {
    return _bff.updateCommunitySupportNetwork(patientId, network);
  }

  @override
  Future<Result<void>> updateSocialHealthSummary(
    PatientId patientId,
    SocialHealthSummary summary,
  ) {
    return _bff.updateSocialHealthSummary(patientId, summary);
  }

  @override
  Future<Result<AppointmentId>> registerAppointment(
    PatientId patientId,
    SocialCareAppointment appointment,
  ) {
    return _bff.registerAppointment(patientId, appointment);
  }

  @override
  Future<Result<void>> updateIntakeInfo(PatientId patientId, IngressInfo info) {
    return _bff.updateIntakeInfo(patientId, info);
  }

  @override
  Future<Result<void>> updatePlacementHistory(
    PatientId patientId,
    PlacementHistory history,
  ) {
    return _bff.updatePlacementHistory(patientId, history);
  }

  @override
  Future<Result<ViolationReportId>> reportViolation(
    PatientId patientId,
    RightsViolationReport report,
  ) {
    return _bff.reportViolation(patientId, report);
  }

  @override
  Future<Result<ReferralId>> createReferral(
    PatientId patientId,
    Referral referral,
  ) {
    return _bff.createReferral(patientId, referral);
  }

  PatientDetailResult _toDetailResult(Patient patient) {
    final detail = _toPatientDetail(patient);
    return PatientDetailResult(
      patientDetail: detail,
      fichas: FichaStatus.fromDetail(detail),
    );
  }

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
          .map((r) => ReferralDetail.fromJson(const {}))
          .toList(),
      violationReports: patient.violationReports
          .map((v) => ViolationReportDetail.fromJson(const {}))
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
    final now = DateTime.now();
    int age(DateTime birth) => now.year - birth.year;

    int r0to6 = 0,
        r7to14 = 0,
        r15to17 = 0,
        r18to29 = 0,
        r30to59 = 0,
        r60to64 = 0,
        r65to69 = 0,
        r70plus = 0;

    for (final m in patient.familyMembers) {
      final a = age(m.birthDate.date);
      if (a <= 6) {
        r0to6++;
      } else if (a <= 14) {
        r7to14++;
      } else if (a <= 17) {
        r15to17++;
      } else if (a <= 29) {
        r18to29++;
      } else if (a <= 59) {
        r30to59++;
      } else if (a <= 64) {
        r60to64++;
      } else if (a <= 69) {
        r65to69++;
      } else {
        r70plus++;
      }
    }

    return ComputedAnalyticsDetail(
      ageProfile: AgeProfileDetail(
        range0to6: r0to6,
        range7to14: r7to14,
        range15to17: r15to17,
        range18to29: r18to29,
        range30to59: r30to59,
        range60to64: r60to64,
        range65to69: r65to69,
        range70Plus: r70plus,
        totalMembers: patient.familyMembers.length,
      ),
    );
  }
}
