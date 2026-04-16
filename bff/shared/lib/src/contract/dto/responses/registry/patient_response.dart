import 'package:json_annotation/json_annotation.dart';

import '../assessment/community_support_network_response.dart';
import '../assessment/educational_status_response.dart';
import '../assessment/health_status_response.dart';
import '../assessment/housing_condition_response.dart';
import '../assessment/socio_economic_response.dart';
import '../assessment/social_health_summary_response.dart';
import '../assessment/work_and_income_response.dart';
import '../analytics/computed_analytics_response.dart';
import '../care/appointment_response.dart';
import '../care/ingress_info_response.dart';
import '../protection/placement_history_response.dart';
import '../protection/referral_response.dart';
import '../protection/violation_report_response.dart';
import 'address_response.dart';
import 'civil_documents_response.dart';
import 'diagnosis_response.dart';
import 'discharge_info_response.dart';
import 'family_member_response.dart';
import 'personal_data_response.dart';
import 'social_identity_response.dart';
import 'withdraw_info_response.dart';

part 'patient_response.g.dart';

@JsonSerializable()
class PatientResponse {
  const PatientResponse({
    required this.patientId,
    required this.personId,
    this.version = 0,
    this.status = 'admitted',
    this.prRelationshipId,
    this.dischargeInfo,
    this.withdrawInfo,
    this.personalData,
    this.civilDocuments,
    this.address,
    this.socialIdentity,
    this.familyMembers = const [],
    this.diagnoses = const [],
    this.housingCondition,
    this.socioeconomicSituation,
    this.workAndIncome,
    this.educationalStatus,
    this.healthStatus,
    this.communitySupportNetwork,
    this.socialHealthSummary,
    this.appointments = const [],
    this.intakeInfo,
    this.placementHistory,
    this.violationReports = const [],
    this.referrals = const [],
    this.computedAnalytics,
  });

  factory PatientResponse.fromJson(Map<String, dynamic> json) =>
      _$PatientResponseFromJson(json);

  final String patientId;
  final String personId;
  final int version;
  final String status;
  final String? prRelationshipId;

  final DischargeInfoResponse? dischargeInfo;
  final WithdrawInfoResponse? withdrawInfo;

  final PersonalDataResponse? personalData;
  final CivilDocumentsResponse? civilDocuments;
  final AddressResponse? address;
  final SocialIdentityResponse? socialIdentity;
  final List<FamilyMemberResponse> familyMembers;

  @JsonKey(readValue: _readDiagnoses)
  final List<DiagnosisResponse> diagnoses;

  final HousingConditionResponse? housingCondition;
  final SocioEconomicResponse? socioeconomicSituation;
  final WorkAndIncomeResponse? workAndIncome;
  final EducationalStatusResponse? educationalStatus;
  final HealthStatusResponse? healthStatus;
  final CommunitySupportNetworkResponse? communitySupportNetwork;
  final SocialHealthSummaryResponse? socialHealthSummary;

  final List<AppointmentResponse> appointments;
  final IngressInfoResponse? intakeInfo;

  final PlacementHistoryResponse? placementHistory;
  final List<ViolationReportResponse> violationReports;
  final List<ReferralResponse> referrals;

  final ComputedAnalyticsResponse? computedAnalytics;

  static Object? _readDiagnoses(Map<dynamic, dynamic> json, String key) =>
      json['initialDiagnoses'] ?? json['diagnoses'] ?? const [];

  Map<String, dynamic> toJson() => _$PatientResponseToJson(this);
}
