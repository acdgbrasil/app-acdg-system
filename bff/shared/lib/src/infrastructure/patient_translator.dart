import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import 'mappers/assessment_mapper.dart';
import 'mappers/care_mapper.dart';
import 'mappers/json_helpers.dart';
import 'mappers/protection_mapper.dart';
import 'mappers/registry_mapper.dart';

// Sub-mappers are internal implementation details.
// Consumers should use PatientTranslator's static methods (delegate aliases)
// to avoid name collisions with mappers in other packages.

/// Orchestrates the conversion of [Patient] aggregates to/from JSON.
///
/// Delegates to bounded-context-specific mappers:
/// - [RegistryMapper] — PersonalData, CivilDocuments, Address, FamilyMember, Diagnosis, SocialIdentity
/// - [AssessmentMapper] — Housing, SocioEconomic, WorkAndIncome, Educational, Health, CommunitySupport, SocialHealthSummary
/// - [CareMapper] — Appointment, IntakeInfo
/// - [ProtectionMapper] — PlacementHistory, ViolationReport, Referral
class PatientTranslator {
  /// Default prRelationshipId used when the server response omits it.
  static const _defaultPrRelationshipId =
      '00000000-0000-0000-0000-000000000000';

  // ── To JSON ─────────────────────────────────────────────────

  static Map<String, dynamic> toJson(Patient p) => {
        'patientId': p.id.value,
        'personId': p.personId.value,
        'version': p.version,
        'prRelationshipId': p.prRelationshipId.value,
        'personalData': p.personalData == null
            ? null
            : RegistryMapper.personalDataToJson(p.personalData!),
        'civilDocuments': p.civilDocuments == null
            ? null
            : RegistryMapper.civilDocumentsToJson(p.civilDocuments!),
        'address':
            p.address == null ? null : RegistryMapper.addressToJson(p.address!),
        'familyMembers':
            p.familyMembers.map(RegistryMapper.familyMemberToJson).toList(),
        'initialDiagnoses':
            p.diagnoses.map(RegistryMapper.diagnosisToJson).toList(),
        'socialIdentity': p.socialIdentity == null
            ? null
            : RegistryMapper.socialIdentityToJson(p.socialIdentity!),
        'housingCondition': p.housingCondition == null
            ? null
            : AssessmentMapper.housingConditionToJson(p.housingCondition!),
        'socioeconomicSituation': p.socioeconomicSituation == null
            ? null
            : AssessmentMapper.socioEconomicToJson(p.socioeconomicSituation!),
        'workAndIncome': p.workAndIncome == null
            ? null
            : AssessmentMapper.workAndIncomeToJson(p.workAndIncome!),
        'educationalStatus': p.educationalStatus == null
            ? null
            : AssessmentMapper.educationalStatusToJson(p.educationalStatus!),
        'healthStatus': p.healthStatus == null
            ? null
            : AssessmentMapper.healthStatusToJson(p.healthStatus!),
        'communitySupportNetwork': p.communitySupportNetwork == null
            ? null
            : AssessmentMapper.communitySupportToJson(
                p.communitySupportNetwork!),
        'socialHealthSummary': p.socialHealthSummary == null
            ? null
            : AssessmentMapper.socialHealthSummaryToJson(
                p.socialHealthSummary!),
        'appointments':
            p.appointments.map(CareMapper.appointmentToJson).toList(),
        'intakeInfo': p.intakeInfo == null
            ? null
            : CareMapper.intakeInfoToJson(p.intakeInfo!),
        'placementHistory': p.placementHistory == null
            ? null
            : ProtectionMapper.placementHistoryToJson(p.placementHistory!),
        'violationReports': p.violationReports
            .map(ProtectionMapper.violationReportToJson)
            .toList(),
        'referrals':
            p.referrals.map(ProtectionMapper.referralToJson).toList(),
      };

  // ── From JSON (via DTO) ──────────────────────────────────────

  /// Convenience entry point: parses raw JSON through [PatientRemote] first.
  static Result<Patient> fromJson(Map<String, dynamic> json) =>
      toDomain(PatientRemote.fromJson(json));

  /// Converts a type-safe [PatientRemote] into the domain [Patient] aggregate.
  static Result<Patient> toDomain(PatientRemote dto) {
    final PatientId patientId;
    switch (PatientId.create(dto.patientId)) {
      case Success(:final value): patientId = value;
      case Failure(:final error): return Failure('patient.patientId: $error');
    }

    final PersonId personId;
    switch (PersonId.create(dto.personId)) {
      case Success(:final value): personId = value;
      case Failure(:final error): return Failure('patient.personId: $error');
    }

    final LookupId prRelationshipId;
    switch (LookupId.create(dto.prRelationshipId ?? _defaultPrRelationshipId)) {
      case Success(:final value): prRelationshipId = value;
      case Failure(:final error): return Failure('patient.prRelationshipId: $error');
    }

    final PersonalData? personalData;
    switch (optionalFromJson(dto.personalData, RegistryMapper.personalDataFromJson)) {
      case Success(:final value): personalData = value;
      case Failure(:final error): return Failure(error);
    }

    final CivilDocuments? civilDocuments;
    switch (optionalFromJson(dto.civilDocuments, RegistryMapper.civilDocumentsFromJson)) {
      case Success(:final value): civilDocuments = value;
      case Failure(:final error): return Failure(error);
    }

    final Address? address;
    switch (optionalFromJson(dto.address, RegistryMapper.addressFromJson)) {
      case Success(:final value): address = value;
      case Failure(:final error): return Failure(error);
    }

    final List<FamilyMember> familyMembers;
    switch (listFromJson(dto.familyMembers, RegistryMapper.familyMemberFromJson, field: 'patient.familyMembers')) {
      case Success(:final value): familyMembers = value;
      case Failure(:final error): return Failure(error);
    }

    final List<Diagnosis> diagnoses;
    switch (listFromJson(dto.diagnoses, RegistryMapper.diagnosisFromJson, field: 'patient.diagnoses')) {
      case Success(:final value): diagnoses = value;
      case Failure(:final error): return Failure(error);
    }

    final SocialIdentity? socialIdentity;
    switch (optionalFromJson(dto.socialIdentity, RegistryMapper.socialIdentityFromJson)) {
      case Success(:final value): socialIdentity = value;
      case Failure(:final error): return Failure(error);
    }

    final HousingCondition? housingCondition;
    switch (optionalFromJson(dto.housingCondition, AssessmentMapper.housingConditionFromJson)) {
      case Success(:final value): housingCondition = value;
      case Failure(:final error): return Failure(error);
    }

    final SocioEconomicSituation? socioeconomicSituation;
    switch (optionalFromJson(dto.socioeconomicSituation, AssessmentMapper.socioEconomicFromJson)) {
      case Success(:final value): socioeconomicSituation = value;
      case Failure(:final error): return Failure(error);
    }

    final WorkAndIncome? workAndIncome;
    switch (optionalFromJson(dto.workAndIncome, AssessmentMapper.workAndIncomeFromJson)) {
      case Success(:final value): workAndIncome = value;
      case Failure(:final error): return Failure(error);
    }

    final EducationalStatus? educationalStatus;
    switch (optionalFromJson(dto.educationalStatus, AssessmentMapper.educationalStatusFromJson)) {
      case Success(:final value): educationalStatus = value;
      case Failure(:final error): return Failure(error);
    }

    final HealthStatus? healthStatus;
    switch (optionalFromJson(dto.healthStatus, AssessmentMapper.healthStatusFromJson)) {
      case Success(:final value): healthStatus = value;
      case Failure(:final error): return Failure(error);
    }

    final CommunitySupportNetwork? communitySupportNetwork;
    switch (optionalFromJson(dto.communitySupportNetwork, AssessmentMapper.communitySupportFromJson)) {
      case Success(:final value): communitySupportNetwork = value;
      case Failure(:final error): return Failure(error);
    }

    final SocialHealthSummary? socialHealthSummary;
    switch (optionalFromJson(dto.socialHealthSummary, AssessmentMapper.socialHealthSummaryFromJson)) {
      case Success(:final value): socialHealthSummary = value;
      case Failure(:final error): return Failure(error);
    }

    final List<SocialCareAppointment> appointments;
    switch (listFromJson(dto.appointments, CareMapper.appointmentFromJson, field: 'patient.appointments')) {
      case Success(:final value): appointments = value;
      case Failure(:final error): return Failure(error);
    }

    final IngressInfo? intakeInfo;
    switch (optionalFromJson(dto.intakeInfo, CareMapper.intakeInfoFromJson)) {
      case Success(:final value): intakeInfo = value;
      case Failure(:final error): return Failure(error);
    }

    final PlacementHistory? placementHistory;
    switch (optionalFromJson(dto.placementHistory, ProtectionMapper.placementHistoryFromJson)) {
      case Success(:final value): placementHistory = value;
      case Failure(:final error): return Failure(error);
    }

    final List<RightsViolationReport> violationReports;
    switch (listFromJson(dto.violationReports, ProtectionMapper.violationReportFromJson, field: 'patient.violationReports')) {
      case Success(:final value): violationReports = value;
      case Failure(:final error): return Failure(error);
    }

    final List<Referral> referrals;
    switch (listFromJson(dto.referrals, ProtectionMapper.referralFromJson, field: 'patient.referrals')) {
      case Success(:final value): referrals = value;
      case Failure(:final error): return Failure(error);
    }

    return Success(Patient.reconstitute(
      id: patientId,
      version: dto.version,
      personId: personId,
      prRelationshipId: prRelationshipId,
      personalData: personalData,
      civilDocuments: civilDocuments,
      address: address,
      familyMembers: familyMembers,
      diagnoses: diagnoses,
      socialIdentity: socialIdentity,
      housingCondition: housingCondition,
      socioeconomicSituation: socioeconomicSituation,
      workAndIncome: workAndIncome,
      educationalStatus: educationalStatus,
      healthStatus: healthStatus,
      communitySupportNetwork: communitySupportNetwork,
      socialHealthSummary: socialHealthSummary,
      appointments: appointments,
      intakeInfo: intakeInfo,
      placementHistory: placementHistory,
      violationReports: violationReports,
      referrals: referrals,
    ));
  }

  // ── Delegate aliases (backward compatibility for callers) ───
  //
  // These static methods delegate to the bounded-context mappers
  // so existing callers (SyncEngine, LocalRepository, BFF remote)
  // can still use `PatientTranslator.methodName(...)` without changes.

  // Registry
  static Map<String, dynamic> personalDataToJson(PersonalData d) =>
      RegistryMapper.personalDataToJson(d);
  static Map<String, dynamic> civilDocumentsToJson(CivilDocuments d) =>
      RegistryMapper.civilDocumentsToJson(d);
  static Map<String, dynamic> addressToJson(Address a) =>
      RegistryMapper.addressToJson(a);
  static Map<String, dynamic> familyMemberToJson(FamilyMember m) =>
      RegistryMapper.familyMemberToJson(m);
  static Map<String, dynamic> diagnosisToJson(Diagnosis d) =>
      RegistryMapper.diagnosisToJson(d);
  static Map<String, dynamic> socialIdentityToJson(SocialIdentity i) =>
      RegistryMapper.socialIdentityToJson(i);
  static Result<PersonalData> personalDataFromJson(Map<String, dynamic> j) =>
      RegistryMapper.personalDataFromJson(j);
  static Result<CivilDocuments> civilDocumentsFromJson(Map<String, dynamic> j) =>
      RegistryMapper.civilDocumentsFromJson(j);
  static Result<Address> addressFromJson(Map<String, dynamic> j) =>
      RegistryMapper.addressFromJson(j);
  static Result<FamilyMember> familyMemberFromJson(Map<String, dynamic> j) =>
      RegistryMapper.familyMemberFromJson(j);
  static Result<Diagnosis> diagnosisFromJson(Map<String, dynamic> j) =>
      RegistryMapper.diagnosisFromJson(j);
  static Result<SocialIdentity> socialIdentityFromJson(Map<String, dynamic> j) =>
      RegistryMapper.socialIdentityFromJson(j);

  // Assessment
  static Map<String, dynamic> housingConditionToJson(HousingCondition c) =>
      AssessmentMapper.housingConditionToJson(c);
  static Map<String, dynamic> socioEconomicToJson(SocioEconomicSituation s) =>
      AssessmentMapper.socioEconomicToJson(s);
  static Map<String, dynamic> socialBenefitToJson(SocialBenefit b) =>
      AssessmentMapper.socialBenefitToJson(b);
  static Map<String, dynamic> workAndIncomeToJson(WorkAndIncome w) =>
      AssessmentMapper.workAndIncomeToJson(w);
  static Map<String, dynamic> educationalStatusToJson(EducationalStatus e) =>
      AssessmentMapper.educationalStatusToJson(e);
  static Map<String, dynamic> healthStatusToJson(HealthStatus h) =>
      AssessmentMapper.healthStatusToJson(h);
  static Map<String, dynamic> communitySupportToJson(CommunitySupportNetwork c) =>
      AssessmentMapper.communitySupportToJson(c);
  static Map<String, dynamic> socialHealthSummaryToJson(SocialHealthSummary s) =>
      AssessmentMapper.socialHealthSummaryToJson(s);
  static Result<HousingCondition> housingConditionFromJson(Map<String, dynamic> j) =>
      AssessmentMapper.housingConditionFromJson(j);
  static Result<SocioEconomicSituation> socioEconomicFromJson(Map<String, dynamic> j) =>
      AssessmentMapper.socioEconomicFromJson(j);
  static Result<SocialBenefit> socialBenefitFromJson(Map<String, dynamic> j) =>
      AssessmentMapper.socialBenefitFromJson(j);
  static Result<WorkAndIncome> workAndIncomeFromJson(Map<String, dynamic> j) =>
      AssessmentMapper.workAndIncomeFromJson(j);
  static Result<EducationalStatus> educationalStatusFromJson(Map<String, dynamic> j) =>
      AssessmentMapper.educationalStatusFromJson(j);
  static Result<HealthStatus> healthStatusFromJson(Map<String, dynamic> j) =>
      AssessmentMapper.healthStatusFromJson(j);
  static Result<CommunitySupportNetwork> communitySupportFromJson(Map<String, dynamic> j) =>
      AssessmentMapper.communitySupportFromJson(j);
  static Result<SocialHealthSummary> socialHealthSummaryFromJson(Map<String, dynamic> j) =>
      AssessmentMapper.socialHealthSummaryFromJson(j);

  // Care
  static Map<String, dynamic> appointmentToJson(SocialCareAppointment a) =>
      CareMapper.appointmentToJson(a);
  static Map<String, dynamic> intakeInfoToJson(IngressInfo i) =>
      CareMapper.intakeInfoToJson(i);
  static Result<SocialCareAppointment> appointmentFromJson(Map<String, dynamic> j) =>
      CareMapper.appointmentFromJson(j);
  static Result<IngressInfo> intakeInfoFromJson(Map<String, dynamic> j) =>
      CareMapper.intakeInfoFromJson(j);

  // Protection
  static Map<String, dynamic> placementHistoryToJson(PlacementHistory p) =>
      ProtectionMapper.placementHistoryToJson(p);
  static Map<String, dynamic> violationReportToJson(RightsViolationReport r) =>
      ProtectionMapper.violationReportToJson(r);
  static Map<String, dynamic> referralToJson(Referral r) =>
      ProtectionMapper.referralToJson(r);
  static Result<PlacementHistory> placementHistoryFromJson(Map<String, dynamic> j) =>
      ProtectionMapper.placementHistoryFromJson(j);
  static Result<RightsViolationReport> violationReportFromJson(Map<String, dynamic> j) =>
      ProtectionMapper.violationReportFromJson(j);
  static Result<Referral> referralFromJson(Map<String, dynamic> j) =>
      ProtectionMapper.referralFromJson(j);
}
