import 'assessment/community_support_network.dart';
import 'assessment/educational_status.dart';
import 'assessment/health_status.dart';
import 'assessment/housing_condition.dart';
import 'assessment/social_health_summary.dart';
import 'assessment/socio_economic_situation.dart';
import 'assessment/work_and_income.dart';
import 'care/appointment.dart';
import 'care/intake_info.dart';
import 'computed_analytics.dart';
import 'family_member.dart';
import 'protection/placement_history.dart';
import 'protection/referral.dart';
import 'protection/violation_report.dart';
import 'value_objects/cep.dart';
import 'value_objects/cpf.dart';
import 'value_objects/nis.dart';

/// Full patient aggregate projection.
final class Patient {
  const Patient({
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

  final String patientId;
  final String personId;
  final int version;

  // Personal info
  final PersonalData? personalData;
  final CivilDocuments? civilDocuments;
  final Address? address;
  final SocialIdentity? socialIdentity;

  // Composition
  final List<FamilyMember> familyMembers;
  final List<Diagnosis> diagnoses;

  // Assessment
  final HousingCondition? housingCondition;
  final SocioEconomicSituation? socioeconomicSituation;
  final WorkAndIncome? workAndIncome;
  final EducationalStatus? educationalStatus;
  final HealthStatus? healthStatus;
  final CommunitySupportNetwork? communitySupportNetwork;
  final SocialHealthSummary? socialHealthSummary;

  // Care
  final List<Appointment> appointments;
  final IntakeInfo? intakeInfo;

  // Protection
  final PlacementHistory? placementHistory;
  final List<Referral> referrals;
  final List<ViolationReport> violationReports;

  // Analytics (server-computed)
  final ComputedAnalytics computedAnalytics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Patient && other.patientId == patientId;

  @override
  int get hashCode => patientId.hashCode;

  @override
  String toString() => 'Patient(id: $patientId, v$version)';
}

/// Personal data of the patient.
final class PersonalData {
  const PersonalData({
    this.firstName,
    this.lastName,
    this.motherName,
    this.nationality,
    this.sex,
    this.socialName,
    this.phone,
    this.birthDate,
  });

  final String? firstName;
  final String? lastName;
  final String? motherName;
  final String? nationality;
  final String? sex;
  final String? socialName;
  final String? phone;
  final DateTime? birthDate;

  String get fullName =>
      [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
}

/// Civil documents of the patient.
final class CivilDocuments {
  const CivilDocuments({this.cpf, this.nis, this.rgDocument});

  final Cpf? cpf;
  final Nis? nis;
  final RgDocument? rgDocument;
}

/// RG document details.
final class RgDocument {
  const RgDocument({
    this.number,
    this.issuingState,
    this.issuingAgency,
    this.issueDate,
  });

  final String? number;
  final String? issuingState;
  final String? issuingAgency;
  final DateTime? issueDate;
}

/// Patient address.
final class Address {
  const Address({
    this.cep,
    this.isShelter,
    this.residenceLocation,
    this.street,
    this.neighborhood,
    this.number,
    this.complement,
    this.state,
    this.city,
  });

  final Cep? cep;
  final bool? isShelter;
  final String? residenceLocation;
  final String? street;
  final String? neighborhood;
  final String? number;
  final String? complement;
  final String? state;
  final String? city;
}

/// Social identity classification.
final class SocialIdentity {
  const SocialIdentity({this.typeId, this.otherDescription});

  final String? typeId;
  final String? otherDescription;
}

/// An initial diagnosis (ICD-10).
final class Diagnosis {
  const Diagnosis({this.icdCode, this.description, this.date});

  final String? icdCode;
  final String? description;
  final DateTime? date;
}
