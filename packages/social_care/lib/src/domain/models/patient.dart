import 'package:core/core.dart';

import 'address.dart';
import 'appointment.dart';
import 'civil_documents.dart';
import 'community_support.dart';
import 'diagnosis.dart';
import 'educational_status.dart';
import 'family_member.dart';
import 'health_status.dart';
import 'housing_condition.dart';
import 'intake_info.dart';
import 'personal_data.dart';
import 'placement_history.dart';
import 'referral.dart';
import 'social_health_summary.dart';
import 'social_identity.dart';
import 'socio_economic_situation.dart';
import 'violation_report.dart';
import 'work_and_income.dart';

/// Root aggregate representing a patient under social care.
///
/// Domain-level schema exposed to the UI. The BFF is the only place where
/// business rules that cross assessments run; the Flutter app treats this
/// aggregate as read-mostly data with optimistic edits feeding back into
/// commands.
class Patient with Equatable {
  const Patient({
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
    this.socioEconomicSituation,
    this.workAndIncome,
    this.educationalStatus,
    this.healthStatus,
    this.communitySupport,
    this.socialHealthSummary,
    this.appointments = const [],
    this.intakeInfo,
    this.placementHistory,
    this.violationReports = const [],
    this.referrals = const [],
  });

  final String patientId;
  final String personId;
  final int version;
  final String status;
  final String? prRelationshipId;

  final DischargeInfo? dischargeInfo;
  final WithdrawInfo? withdrawInfo;

  final PersonalData? personalData;
  final CivilDocuments? civilDocuments;
  final Address? address;
  final SocialIdentity? socialIdentity;
  final List<FamilyMember> familyMembers;

  final List<Diagnosis> diagnoses;

  final HousingCondition? housingCondition;
  final SocioEconomicSituation? socioEconomicSituation;
  final WorkAndIncome? workAndIncome;
  final EducationalStatus? educationalStatus;
  final HealthStatus? healthStatus;
  final CommunitySupport? communitySupport;
  final SocialHealthSummary? socialHealthSummary;

  final List<Appointment> appointments;
  final IntakeInfo? intakeInfo;

  final PlacementHistory? placementHistory;
  final List<ViolationReport> violationReports;
  final List<Referral> referrals;

  Patient copyWith({
    String? patientId,
    String? personId,
    int? version,
    String? status,
    String? prRelationshipId,
    DischargeInfo? dischargeInfo,
    WithdrawInfo? withdrawInfo,
    PersonalData? personalData,
    CivilDocuments? civilDocuments,
    Address? address,
    SocialIdentity? socialIdentity,
    List<FamilyMember>? familyMembers,
    List<Diagnosis>? diagnoses,
    HousingCondition? housingCondition,
    SocioEconomicSituation? socioEconomicSituation,
    WorkAndIncome? workAndIncome,
    EducationalStatus? educationalStatus,
    HealthStatus? healthStatus,
    CommunitySupport? communitySupport,
    SocialHealthSummary? socialHealthSummary,
    List<Appointment>? appointments,
    IntakeInfo? intakeInfo,
    PlacementHistory? placementHistory,
    List<ViolationReport>? violationReports,
    List<Referral>? referrals,
  }) {
    return Patient(
      patientId: patientId ?? this.patientId,
      personId: personId ?? this.personId,
      version: version ?? this.version,
      status: status ?? this.status,
      prRelationshipId: prRelationshipId ?? this.prRelationshipId,
      dischargeInfo: dischargeInfo ?? this.dischargeInfo,
      withdrawInfo: withdrawInfo ?? this.withdrawInfo,
      personalData: personalData ?? this.personalData,
      civilDocuments: civilDocuments ?? this.civilDocuments,
      address: address ?? this.address,
      socialIdentity: socialIdentity ?? this.socialIdentity,
      familyMembers: familyMembers ?? this.familyMembers,
      diagnoses: diagnoses ?? this.diagnoses,
      housingCondition: housingCondition ?? this.housingCondition,
      socioEconomicSituation:
          socioEconomicSituation ?? this.socioEconomicSituation,
      workAndIncome: workAndIncome ?? this.workAndIncome,
      educationalStatus: educationalStatus ?? this.educationalStatus,
      healthStatus: healthStatus ?? this.healthStatus,
      communitySupport: communitySupport ?? this.communitySupport,
      socialHealthSummary: socialHealthSummary ?? this.socialHealthSummary,
      appointments: appointments ?? this.appointments,
      intakeInfo: intakeInfo ?? this.intakeInfo,
      placementHistory: placementHistory ?? this.placementHistory,
      violationReports: violationReports ?? this.violationReports,
      referrals: referrals ?? this.referrals,
    );
  }

  @override
  List<Object?> get props => [
    patientId,
    personId,
    version,
    status,
    prRelationshipId,
    dischargeInfo,
    withdrawInfo,
    personalData,
    civilDocuments,
    address,
    socialIdentity,
    familyMembers,
    diagnoses,
    housingCondition,
    socioEconomicSituation,
    workAndIncome,
    educationalStatus,
    healthStatus,
    communitySupport,
    socialHealthSummary,
    appointments,
    intakeInfo,
    placementHistory,
    violationReports,
    referrals,
  ];
}

/// Discharge information attached to a closed patient record.
class DischargeInfo with Equatable {
  const DischargeInfo({
    required this.reason,
    required this.dischargedAt,
    required this.dischargedBy,
    this.notes,
  });

  final String reason;
  final String dischargedAt;
  final String dischargedBy;
  final String? notes;

  DischargeInfo copyWith({
    String? reason,
    String? dischargedAt,
    String? dischargedBy,
    String? notes,
  }) {
    return DischargeInfo(
      reason: reason ?? this.reason,
      dischargedAt: dischargedAt ?? this.dischargedAt,
      dischargedBy: dischargedBy ?? this.dischargedBy,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [reason, dischargedAt, dischargedBy, notes];
}

/// Withdrawal information attached to a patient record when the family
/// actively removes themselves from the service.
class WithdrawInfo with Equatable {
  const WithdrawInfo({
    required this.reason,
    required this.withdrawnAt,
    required this.withdrawnBy,
    this.notes,
  });

  final String reason;
  final String withdrawnAt;
  final String withdrawnBy;
  final String? notes;

  WithdrawInfo copyWith({
    String? reason,
    String? withdrawnAt,
    String? withdrawnBy,
    String? notes,
  }) {
    return WithdrawInfo(
      reason: reason ?? this.reason,
      withdrawnAt: withdrawnAt ?? this.withdrawnAt,
      withdrawnBy: withdrawnBy ?? this.withdrawnBy,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [reason, withdrawnAt, withdrawnBy, notes];
}

/// Lightweight patient projection used in listing screens.
class PatientSummary with Equatable {
  const PatientSummary({
    required this.patientId,
    required this.personId,
    this.firstName,
    this.lastName,
    this.fullName,
    this.primaryDiagnosis,
    this.memberCount = 0,
    this.status = 'admitted',
  });

  final String patientId;
  final String personId;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? primaryDiagnosis;
  final int memberCount;
  final String status;

  PatientSummary copyWith({
    String? patientId,
    String? personId,
    String? firstName,
    String? lastName,
    String? fullName,
    String? primaryDiagnosis,
    int? memberCount,
    String? status,
  }) {
    return PatientSummary(
      patientId: patientId ?? this.patientId,
      personId: personId ?? this.personId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      primaryDiagnosis: primaryDiagnosis ?? this.primaryDiagnosis,
      memberCount: memberCount ?? this.memberCount,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    patientId,
    personId,
    firstName,
    lastName,
    fullName,
    primaryDiagnosis,
    memberCount,
    status,
  ];
}
