import 'package:shared/shared.dart';

import 'ficha_status.dart';
import 'patient_detail.dart';
import 'patient_detail_result.dart';

/// Translates a domain [Patient] into UI-ready [PatientDetailResult].
///
/// Extracted from the repository layer so the ViewModel can convert
/// a plain [Patient] into the detail + fichas bundle the UI expects.
class PatientDetailTranslator {
  PatientDetailTranslator._();

  /// Converts a [Patient] into a [PatientDetailResult] with fichas.
  static PatientDetailResult toDetailResult(Patient patient) {
    final detail = toPatientDetail(patient);
    return PatientDetailResult(
      patientDetail: detail,
      fichas: FichaStatus.fromDetail(detail),
    );
  }

  /// Converts a domain [Patient] into a flat [PatientDetail] UI model.
  static PatientDetail toPatientDetail(Patient patient) {
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
            (m) => FamilyMemberDetail(
              id: m.personId.value,
              relationshipId: m.relationshipId.value,
              isPrimaryCaregiver: m.isPrimaryCaregiver,
              residesWithPatient: m.residesWithPatient,
              hasDisability: m.hasDisability,
              birthDate: m.birthDate.date.toIso8601String(),
            ),
          )
          .toList(),
      diagnoses: patient.diagnoses
          .map(
            (d) => DiagnosisDetail(
              id: d.id.value,
              description: d.description,
              date: d.date.date.toIso8601String(),
            ),
          )
          .toList(),
      appointments: patient.appointments
          .map(
            (a) => AppointmentDetail(
              id: a.id.value,
              date: a.date.date.toIso8601String(),
              professionalInChargeId: a.professionalInChargeId.value,
              type: a.type.name,
              summary: a.summary ?? '',
              actionPlan: a.actionPlan ?? '',
            ),
          )
          .toList(),
      referrals: patient.referrals
          .map(
            (r) => ReferralDetail(
              id: r.id.value,
              date: r.date.toIso8601(),
              professionalId: r.requestingProfessionalId.value,
              referredPersonId: r.referredPersonId.value,
              destinationService: r.destinationService.name.toSnakeCaseUpper(),
              reason: r.reason,
              status: r.status.name.toSnakeCaseUpper(),
            ),
          )
          .toList(),
      violationReports: patient.violationReports
          .map(
            (v) => ViolationReportDetail(
              id: v.id.value,
              reportDate: v.reportDate.toIso8601(),
              incidentDate: v.incidentDate?.toIso8601(),
              victimId: v.victimId.value,
              violationType: v.violationType.name.toSnakeCaseUpper(),
              violationTypeId: v.violationTypeId?.value,
              descriptionOfFact: v.descriptionOfFact,
              actionsTaken: v.actionsTaken ?? '',
            ),
          )
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
                      issueDate: docs.rgDocument!.issueDate.date
                          .toIso8601String(),
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
      healthStatus: patient.healthStatus != null
          ? HealthStatusDetail(
              foodInsecurity: patient.healthStatus!.foodInsecurity,
              deficiencies: patient.healthStatus!.deficiencies
                  .map(
                    (d) => DeficiencyDetail(
                      memberId: d.memberId.value,
                      deficiencyTypeId: d.deficiencyTypeId.value,
                      needsConstantCare: d.needsConstantCare,
                      responsibleCaregiverName: d.responsibleCaregiverName,
                    ),
                  )
                  .toList(),
              gestatingMembers: patient.healthStatus!.gestatingMembers
                  .map(
                    (g) => GestatingMemberDetail(
                      memberId: g.memberId.value,
                      monthsGestation: g.monthsGestation,
                      startedPrenatalCare: g.startedPrenatalCare,
                    ),
                  )
                  .toList(),
              constantCareNeeds: patient.healthStatus!.constantCareNeeds
                  .map((id) => id.value)
                  .toList(),
            )
          : null,
      communitySupportNetwork: patient.communitySupportNetwork != null
          ? CommunitySupportNetworkDetail(
              hasRelativeSupport:
                  patient.communitySupportNetwork!.hasRelativeSupport,
              hasNeighborSupport:
                  patient.communitySupportNetwork!.hasNeighborSupport,
              familyConflicts: patient.communitySupportNetwork!.familyConflicts,
              patientParticipatesInGroups:
                  patient.communitySupportNetwork!.patientParticipatesInGroups,
              familyParticipatesInGroups:
                  patient.communitySupportNetwork!.familyParticipatesInGroups,
              patientHasAccessToLeisure:
                  patient.communitySupportNetwork!.patientHasAccessToLeisure,
              facesDiscrimination:
                  patient.communitySupportNetwork!.facesDiscrimination,
            )
          : null,
      housingCondition: patient.housingCondition != null
          ? HousingConditionDetail(
              type: patient.housingCondition!.type.name,
              wallMaterial: patient.housingCondition!.wallMaterial.name,
              waterSupply: patient.housingCondition!.waterSupply.name,
              electricityAccess:
                  patient.housingCondition!.electricityAccess.name,
              sewageDisposal: patient.housingCondition!.sewageDisposal.name,
              wasteCollection: patient.housingCondition!.wasteCollection.name,
              accessibilityLevel:
                  patient.housingCondition!.accessibilityLevel.name,
              numberOfRooms: patient.housingCondition!.numberOfRooms,
              numberOfBedrooms: patient.housingCondition!.numberOfBedrooms,
              numberOfBathrooms: patient.housingCondition!.numberOfBathrooms,
              hasPipedWater: patient.housingCondition!.hasPipedWater,
              isInGeographicRiskArea:
                  patient.housingCondition!.isInGeographicRiskArea,
              hasDifficultAccess: patient.housingCondition!.hasDifficultAccess,
              isInSocialConflictArea:
                  patient.housingCondition!.isInSocialConflictArea,
              hasDiagnosticObservations:
                  patient.housingCondition!.hasDiagnosticObservations,
            )
          : null,
    );
  }

  static ComputedAnalyticsDetail _buildAnalytics(Patient patient) {
    final now = DateTime.now();
    int age(DateTime birth) {
      int a = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        a--;
      }
      return a;
    }

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
