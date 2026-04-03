import 'package:json_annotation/json_annotation.dart';

part 'patient_remote.g.dart';

/// Anemic remote model mirroring the BFF's PatientResponse schema.
///
/// Synced with `contracts/services/social-care/model/schemas/PatientResponse.yaml`.
/// Nested objects remain as [Map<String, dynamic>] until their own remote
/// models are created in future iterations.
@JsonSerializable()
class PatientRemote {
  const PatientRemote({
    required this.patientId,
    required this.personId,
    this.version = 0,
    this.prRelationshipId,
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

  factory PatientRemote.fromJson(Map<String, dynamic> json) =>
      _$PatientRemoteFromJson(json);

  final String patientId;
  final String personId;
  final int version;
  final String? prRelationshipId;

  final Map<String, dynamic>? personalData;
  final Map<String, dynamic>? civilDocuments;
  final Map<String, dynamic>? address;
  final Map<String, dynamic>? socialIdentity;
  final List<Map<String, dynamic>> familyMembers;
  final List<Map<String, dynamic>> diagnoses;
  final Map<String, dynamic>? housingCondition;
  final Map<String, dynamic>? socioeconomicSituation;
  final Map<String, dynamic>? workAndIncome;
  final Map<String, dynamic>? educationalStatus;
  final Map<String, dynamic>? healthStatus;
  final Map<String, dynamic>? communitySupportNetwork;
  final Map<String, dynamic>? socialHealthSummary;
  final List<Map<String, dynamic>> appointments;
  final Map<String, dynamic>? intakeInfo;
  final Map<String, dynamic>? placementHistory;
  final List<Map<String, dynamic>> violationReports;
  final List<Map<String, dynamic>> referrals;
  final Map<String, dynamic>? computedAnalytics;

  Map<String, dynamic> toJson() => _$PatientRemoteToJson(this);
}
