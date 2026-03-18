import 'package:core/core.dart';
import '../../utils/app_error.dart';
import '../assessment/assessment_vos.dart';
import '../assessment/community_support.dart';
import '../assessment/educational_status.dart';
import '../assessment/health_status.dart';
import '../assessment/social_health_summary.dart';
import '../assessment/work_and_income.dart';
import '../care/care_vos.dart';
import '../kernel/address.dart';
import '../kernel/ids.dart';
import '../protection/protection_vos.dart';
import 'family_member.dart';
import 'registry_vos.dart';

/// Agregado Raiz que representa o prontuário completo de um paciente.
final class Patient with Equatable {
  const Patient._({
    required this.id,
    this.version = 1,
    required this.personId,
    required this.prRelationshipId,
    this.personalData,
    this.civilDocuments,
    this.address,
    this.familyMembers = const [],
    this.socialIdentity,
    this.housingCondition,
    this.socioeconomicSituation,
    this.workAndIncome,
    this.educationalStatus,
    this.healthStatus,
    this.communitySupportNetwork,
    this.socialHealthSummary,
    this.appointments = const [],
    this.referrals = const [],
    this.violationReports = const [],
    this.placementHistory,
    this.intakeInfo,
    this.diagnoses = const [],
  });

  // Identidade
  final PatientId id;
  final int version;
  final PersonId personId;

  /// ID da relação da Pessoa de Referência (PR) na tabela de domínios.
  final LookupId prRelationshipId;

  // Dados Civis
  final PersonalData? personalData;
  final CivilDocuments? civilDocuments;
  final Address? address;

  // Família
  final List<FamilyMember> familyMembers;

  // Identidade Social
  final SocialIdentity? socialIdentity;

  // Assessments
  final HousingCondition? housingCondition;
  final SocioEconomicSituation? socioeconomicSituation;
  final WorkAndIncome? workAndIncome;
  final EducationalStatus? educationalStatus;
  final HealthStatus? healthStatus;
  final CommunitySupportNetwork? communitySupportNetwork;
  final SocialHealthSummary? socialHealthSummary;

  // Intervenções
  final List<SocialCareAppointment> appointments;
  final List<Referral> referrals;
  final List<RightsViolationReport> violationReports;
  final PlacementHistory? placementHistory;
  final IngressInfo? intakeInfo;
  final List<Diagnosis> diagnoses;

  @override
  List<Object?> get props => [id]; // Igualdade por ID para Agregados

  /// Fábrica para criação de um novo prontuário com validações de invariantes.
  static Result<Patient> create({
    required PatientId id,
    required PersonId personId,
    PersonalData? personalData,
    CivilDocuments? civilDocuments,
    Address? address,
    required List<Diagnosis> diagnoses,
    List<FamilyMember> familyMembers = const [],
    required LookupId prRelationshipId,
  }) {
    // Invariante: diagnoses não pode ser vazio
    if (diagnoses.isEmpty) {
      return Failure(
        _buildError(
          'PAT-003',
          'Ao menos um diagnóstico (CID) é obrigatório para abertura de prontuário.',
        ),
      );
    }

    // Invariante: Exatamente uma Pessoa de Referência (PR) deve existir na família
    // A PR é identificada pelo relationshipId correspondente ao prRelationshipId configurado.
    final prCount = familyMembers
        .where((m) => m.relationshipId == prRelationshipId)
        .length;
    if (prCount == 0) {
      return Failure(
        _buildError(
          'PAT-008',
          'É necessário exatamente uma Pessoa de Referência (PR) na composição familiar.',
        ),
      );
    }
    if (prCount > 1) {
      return Failure(
        _buildError(
          'PAT-009',
          'Não é permitido mais de uma Pessoa de Referência (PR).',
        ),
      );
    }

    return Success(
      Patient._(
        id: id,
        personId: personId,
        prRelationshipId: prRelationshipId,
        personalData: personalData,
        civilDocuments: civilDocuments,
        address: address,
        diagnoses: List.unmodifiable(diagnoses),
        familyMembers: List.unmodifiable(familyMembers),
      ),
    );
  }

  /// Método para reconstrução (hidratação) a partir do banco de dados, sem disparar eventos ou validações de criação.
  static Patient reconstitute({
    required PatientId id,
    required int version,
    required PersonId personId,
    required LookupId prRelationshipId,
    PersonalData? personalData,
    CivilDocuments? civilDocuments,
    Address? address,
    List<FamilyMember> familyMembers = const [],
    SocialIdentity? socialIdentity,
    HousingCondition? housingCondition,
    SocioEconomicSituation? socioeconomicSituation,
    WorkAndIncome? workAndIncome,
    EducationalStatus? educationalStatus,
    HealthStatus? healthStatus,
    CommunitySupportNetwork? communitySupportNetwork,
    SocialHealthSummary? socialHealthSummary,
    List<SocialCareAppointment> appointments = const [],
    List<Referral> referrals = const [],
    List<RightsViolationReport> violationReports = const [],
    PlacementHistory? placementHistory,
    IngressInfo? intakeInfo,
    List<Diagnosis> diagnoses = const [],
  }) {
    return Patient._(
      id: id,
      version: version,
      personId: personId,
      prRelationshipId: prRelationshipId,
      personalData: personalData,
      civilDocuments: civilDocuments,
      address: address,
      familyMembers: List.unmodifiable(familyMembers),
      socialIdentity: socialIdentity,
      housingCondition: housingCondition,
      socioeconomicSituation: socioeconomicSituation,
      workAndIncome: workAndIncome,
      educationalStatus: educationalStatus,
      healthStatus: healthStatus,
      communitySupportNetwork: communitySupportNetwork,
      socialHealthSummary: socialHealthSummary,
      appointments: List.unmodifiable(appointments),
      referrals: List.unmodifiable(referrals),
      violationReports: List.unmodifiable(violationReports),
      placementHistory: placementHistory,
      intakeInfo: intakeInfo,
      diagnoses: List.unmodifiable(diagnoses),
    );
  }

  Patient copyWith({
    int? version,
    LookupId? prRelationshipId,
    PersonalData? Function()? personalData,
    CivilDocuments? Function()? civilDocuments,
    Address? Function()? address,
    List<FamilyMember>? familyMembers,
    SocialIdentity? Function()? socialIdentity,
    HousingCondition? Function()? housingCondition,
    SocioEconomicSituation? Function()? socioeconomicSituation,
    WorkAndIncome? Function()? workAndIncome,
    EducationalStatus? Function()? educationalStatus,
    HealthStatus? Function()? healthStatus,
    CommunitySupportNetwork? Function()? communitySupportNetwork,
    SocialHealthSummary? Function()? socialHealthSummary,
    List<SocialCareAppointment>? appointments,
    List<Referral>? referrals,
    List<RightsViolationReport>? violationReports,
    PlacementHistory? Function()? placementHistory,
    IngressInfo? Function()? intakeInfo,
    List<Diagnosis>? diagnoses,
  }) {
    return Patient._(
      id: id,
      version: version ?? this.version,
      personId: personId,
      prRelationshipId: prRelationshipId ?? this.prRelationshipId,
      personalData: personalData != null ? personalData() : this.personalData,
      civilDocuments: civilDocuments != null
          ? civilDocuments()
          : this.civilDocuments,
      address: address != null ? address() : this.address,
      familyMembers: familyMembers ?? this.familyMembers,
      socialIdentity: socialIdentity != null
          ? socialIdentity()
          : this.socialIdentity,
      housingCondition: housingCondition != null
          ? housingCondition()
          : this.housingCondition,
      socioeconomicSituation: socioeconomicSituation != null
          ? socioeconomicSituation()
          : this.socioeconomicSituation,
      workAndIncome: workAndIncome != null
          ? workAndIncome()
          : this.workAndIncome,
      educationalStatus: educationalStatus != null
          ? educationalStatus()
          : this.educationalStatus,
      healthStatus: healthStatus != null ? healthStatus() : this.healthStatus,
      communitySupportNetwork: communitySupportNetwork != null
          ? communitySupportNetwork()
          : this.communitySupportNetwork,
      socialHealthSummary: socialHealthSummary != null
          ? socialHealthSummary()
          : this.socialHealthSummary,
      appointments: appointments ?? this.appointments,
      referrals: referrals ?? this.referrals,
      violationReports: violationReports ?? this.violationReports,
      placementHistory: placementHistory != null
          ? placementHistory()
          : this.placementHistory,
      intakeInfo: intakeInfo != null ? intakeInfo() : this.intakeInfo,
      diagnoses: diagnoses ?? this.diagnoses,
    );
  }

  static AppError _buildError(String code, String message) {
    return AppError(
      code: code,
      message: message,
      module: 'social-care/patient',
      kind: 'domainInvariantViolation',
      http: 422,
      observability: const Observability(
        category: ErrorCategory.domainRuleViolation,
        severity: ErrorSeverity.warning,
      ),
    );
  }
}
