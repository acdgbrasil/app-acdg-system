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
      patientId: data['patientId'] as String? ?? '',
      personId: data['personId'] as String? ?? '',
      version: data['version'] as int? ?? 1,
      familyMembers: (data['familyMembers'] as List? ?? [])
          .map((e) => FamilyMemberDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      diagnoses: (data['diagnoses'] as List? ?? data['initialDiagnoses'] as List? ?? [])
          .map((e) => DiagnosisDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      appointments: (data['appointments'] as List? ?? [])
          .map((e) => AppointmentDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      referrals: (data['referrals'] as List? ?? [])
          .map((e) => ReferralDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      violationReports: (data['violationReports'] as List? ?? [])
          .map(
            (e) => ViolationReportDetail.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      computedAnalytics: data['computedAnalytics'] != null
          ? ComputedAnalyticsDetail.fromJson(
              data['computedAnalytics'] as Map<String, dynamic>,
            )
          : const ComputedAnalyticsDetail(
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
}
