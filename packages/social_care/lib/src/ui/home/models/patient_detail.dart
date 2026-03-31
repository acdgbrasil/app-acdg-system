import 'package:shared/shared.dart';

import 'address_detail.dart';
import 'appointment_detail.dart';
import 'civil_documents_detail.dart';
import 'community_support_network_detail.dart';
import 'computed_analytics_detail.dart';
import 'diagnosis_detail.dart';
import 'educational_status_detail.dart';
import 'family_member_detail.dart';
import 'health_status_detail.dart';
import 'housing_condition_detail.dart';
import 'intake_info_detail.dart';
import 'personal_data_detail.dart';
import 'placement_history_detail.dart';
import 'referral_detail.dart';
import 'social_health_summary_detail.dart';
import 'social_identity_detail.dart';
import 'socioeconomic_situation_detail.dart';
import 'violation_report_detail.dart';
import 'work_and_income_detail.dart';

export 'address_detail.dart';
export 'appointment_detail.dart';
export 'civil_documents_detail.dart';
export 'community_support_network_detail.dart';
export 'computed_analytics_detail.dart';
export 'diagnosis_detail.dart';
export 'educational_status_detail.dart';
export 'family_member_detail.dart';
export 'health_status_detail.dart';
export 'housing_condition_detail.dart';
export 'intake_info_detail.dart';
export 'personal_data_detail.dart';
export 'placement_history_detail.dart';
export 'referral_detail.dart';
export 'social_health_summary_detail.dart';
export 'social_identity_detail.dart';
export 'socioeconomic_situation_detail.dart';
export 'violation_report_detail.dart';
export 'work_and_income_detail.dart';

/// UI model that maps the full GET /api/v1/patients/:patientId response.
final class PatientDetail {
  final String patientId;
  final String personId;
  final int version;
  final List<FamilyMemberDetail> familyMembers;
  final List<DiagnosisDetail> diagnoses;
  final List<AppointmentDetail> appointments;
  final List<ReferralDetail> referrals;
  final List<ViolationReportDetail> violationReports;
  final ComputedAnalyticsDetail computedAnalytics;
  final PersonalDataDetail? personalData;
  final CivilDocumentsDetail? civilDocuments;
  final AddressDetail? address;
  final SocialIdentityDetail? socialIdentity;
  final HousingConditionDetail? housingCondition;
  final SocioeconomicSituationDetail? socioeconomicSituation;
  final WorkAndIncomeDetail? workAndIncome;
  final EducationalStatusDetail? educationalStatus;
  final HealthStatusDetail? healthStatus;
  final CommunitySupportNetworkDetail? communitySupportNetwork;
  final SocialHealthSummaryDetail? socialHealthSummary;
  final PlacementHistoryDetail? placementHistory;
  final IntakeInfoDetail? intakeInfo;

  const PatientDetail({
    required this.patientId,
    required this.personId,
    required this.version,
    required this.familyMembers,
    required this.diagnoses,
    required this.appointments,
    required this.referrals,
    required this.violationReports,
    required this.computedAnalytics,
    this.personalData,
    this.civilDocuments,
    this.address,
    this.socialIdentity,
    this.housingCondition,
    this.socioeconomicSituation,
    this.workAndIncome,
    this.educationalStatus,
    this.healthStatus,
    this.communitySupportNetwork,
    this.socialHealthSummary,
    this.placementHistory,
    this.intakeInfo,
  });

  // ── Computed getters for View consumption ──────────────────

  String get fullName {
    final pd = personalData;
    if (pd == null) return '—';
    return '${pd.firstName} ${pd.lastName}'.trim();
  }

  String? get motherName => personalData?.motherName;

  String? get diagnosis =>
      diagnoses.isNotEmpty ? diagnoses.first.description : null;

  String? get birthDate {
    final iso = personalData?.birthDate;
    if (iso == null) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String? get cpf => civilDocuments?.cpf;

  String get status => personalData != null ? 'Ativo' : 'Inativo';

  String? get entryDate {
    if (appointments.isEmpty) return null;
    // Appointments store raw JSON, try to extract date
    return null;
  }

  String? get responsible => null;

  String? get cep => address?.cep;

  String? get phone => personalData?.phone;

  String? get formattedAddress {
    final addr = address;
    if (addr == null) return null;
    final parts = [
      if (addr.street != null) addr.street!,
      if (addr.number != null) addr.number!,
      if (addr.neighborhood != null) addr.neighborhood!,
      '${addr.city} - ${addr.state}',
    ];
    return parts.join(', ');
  }

  factory PatientDetail.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return PatientDetail(
      patientId: data['patientId'] as String,
      personId: data['personId'] as String,
      version: data['version'] as int,
      familyMembers: (data['familyMembers'] as List)
          .map((e) => FamilyMemberDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      diagnoses: (data['diagnoses'] as List)
          .map((e) => DiagnosisDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      appointments: (data['appointments'] as List)
          .map((e) => AppointmentDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      referrals: (data['referrals'] as List)
          .map((e) => ReferralDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      violationReports: (data['violationReports'] as List)
          .map(
            (e) => ViolationReportDetail.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      computedAnalytics: ComputedAnalyticsDetail.fromJson(
        data['computedAnalytics'] as Map<String, dynamic>,
      ),
      personalData: data['personalData'] != null
          ? PersonalDataDetail.fromJson(
              data['personalData'] as Map<String, dynamic>,
            )
          : null,
      civilDocuments: data['civilDocuments'] != null
          ? CivilDocumentsDetail.fromJson(
              data['civilDocuments'] as Map<String, dynamic>,
            )
          : null,
      address: data['address'] != null
          ? AddressDetail.fromJson(data['address'] as Map<String, dynamic>)
          : null,
      socialIdentity: data['socialIdentity'] != null
          ? SocialIdentityDetail.fromJson(
              data['socialIdentity'] as Map<String, dynamic>,
            )
          : null,
      housingCondition: data['housingCondition'] != null
          ? HousingConditionDetail.fromJson(
              data['housingCondition'] as Map<String, dynamic>,
            )
          : null,
      socioeconomicSituation: data['socioeconomicSituation'] != null
          ? SocioeconomicSituationDetail.fromJson(
              data['socioeconomicSituation'] as Map<String, dynamic>,
            )
          : null,
      workAndIncome: data['workAndIncome'] != null
          ? WorkAndIncomeDetail.fromJson(
              data['workAndIncome'] as Map<String, dynamic>,
            )
          : null,
      educationalStatus: data['educationalStatus'] != null
          ? EducationalStatusDetail.fromJson(
              data['educationalStatus'] as Map<String, dynamic>,
            )
          : null,
      healthStatus: data['healthStatus'] != null
          ? HealthStatusDetail.fromJson(
              data['healthStatus'] as Map<String, dynamic>,
            )
          : null,
      communitySupportNetwork: data['communitySupportNetwork'] != null
          ? CommunitySupportNetworkDetail.fromJson(
              data['communitySupportNetwork'] as Map<String, dynamic>,
            )
          : null,
      socialHealthSummary: data['socialHealthSummary'] != null
          ? SocialHealthSummaryDetail.fromJson(
              data['socialHealthSummary'] as Map<String, dynamic>,
            )
          : null,
      placementHistory: data['placementHistory'] != null
          ? PlacementHistoryDetail.fromJson(
              data['placementHistory'] as Map<String, dynamic>,
            )
          : null,
      intakeInfo: data['intakeInfo'] != null
          ? IntakeInfoDetail.fromJson(
              data['intakeInfo'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Maps a domain [Patient] to [PatientDetail] for UI display.
  factory PatientDetail.fromPatient(Patient patient) {
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
          .map((r) => ReferralDetail.fromJson({}))
          .toList(),
      violationReports: patient.violationReports
          .map((v) => ViolationReportDetail.fromJson({}))
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
    );
  }

  static ComputedAnalyticsDetail _buildAnalytics(Patient patient) {
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
