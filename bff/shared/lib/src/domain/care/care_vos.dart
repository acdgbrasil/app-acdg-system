import 'package:core/core.dart';
import '../../utils/app_error.dart';
import '../../utils/string_helpers.dart';
import '../kernel/ids.dart';
import '../kernel/time_stamp.dart';

// =============================================================================
// ICD CODE
// =============================================================================

final class IcdCode with Equatable {
  const IcdCode._(this.value);

  /// Ex: "B20.1"
  final String value;

  String get normalized => value.replaceAll('.', '');

  @override
  List<Object?> get props => [value];

  bool isEquivalent(IcdCode other) => normalized == other.normalized;

  static Result<IcdCode> create(String? rawValue, {bool requiresDot = false, bool autoDot = true}) {
    if (rawValue == null || rawValue.normalizedTrim().isEmpty) {
      return Failure(_buildError('ICD-001', 'Código CID não pode ser vazio.'));
    }

    var val = rawValue.normalizedTrim().toUpperCase();

    if (requiresDot && !val.contains('.')) {
      return Failure(
        AppError(code: 'ICD-002', message: 'Formato inválido de CID', module: 'social-care/icd-code', kind: 'domainValidation', http: 422, observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error))
      );
    }

    if (autoDot && val.length >= 3 && !val.contains('.')) {
      val = '${val.substring(0, val.length - 1)}.${val.substring(val.length - 1)}';
    }

    return Success(IcdCode._(val));
  }

  static AppError _buildError(String code, String message) {
    return AppError(code: code, message: message, module: 'social-care/icd-code', kind: 'domainValidation', http: 422, observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.warning));
  }
}

// =============================================================================
// DIAGNOSIS
// =============================================================================

final class Diagnosis with Equatable {
  const Diagnosis._({required this.id, required this.date, required this.description});

  final IcdCode id;
  final TimeStamp date;
  final String description;

  @override
  List<Object?> get props => [id, date, description];

  Diagnosis copyWith({
    IcdCode? id,
    TimeStamp? date,
    String? description,
  }) {
    return Diagnosis._(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }

  static Result<Diagnosis> create({required IcdCode id, required TimeStamp? date, required String? description, TimeStamp? now}) {
    if (date == null) return Failure(_buildDiagError('DIA-001', 'Data não pode ser nula'));
    
    final refNow = now ?? TimeStamp.now;
    if (date.date.isAfter(refNow.date)) {
      return Failure(_buildDiagError('DIA-001', 'Data do diagnóstico não pode ser no futuro'));
    }

    if (date.year < 0) {
      return Failure(
        AppError(code: 'DIA-002', message: 'Ano do diagnóstico deve ser >= 0', module: 'social-care/diagnosis', kind: 'domainValidation', http: 422, observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.error))
      );
    }

    final desc = description?.normalizedTrim();
    if (desc == null || desc.isEmpty) {
      return Failure(_buildDiagError('DIA-003', 'Descrição do diagnóstico não pode ser vazia'));
    }

    return Success(Diagnosis._(id: id, date: date, description: desc));
  }

  static AppError _buildDiagError(String code, String message) {
    return AppError(code: code, message: message, module: 'social-care/diagnosis', kind: 'domainValidation', http: 422, observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.warning));
  }
}

// =============================================================================
// INGRESS INFO
// =============================================================================

final class ProgramLink with Equatable {
  const ProgramLink({required this.programId, this.observation});
  final LookupId programId;
  final String? observation;
  @override
  List<Object?> get props => [programId, observation];
}

final class IngressInfo with Equatable {
  const IngressInfo._({required this.ingressTypeId, this.originName, this.originContact, required this.serviceReason, required this.linkedSocialPrograms});

  final LookupId ingressTypeId;
  final String? originName;
  final String? originContact;
  final String serviceReason;
  final List<ProgramLink> linkedSocialPrograms;

  @override
  List<Object?> get props => [ingressTypeId, originName, originContact, serviceReason, linkedSocialPrograms];

  IngressInfo copyWith({
    LookupId? ingressTypeId,
    String? Function()? originName,
    String? Function()? originContact,
    String? serviceReason,
    List<ProgramLink>? linkedSocialPrograms,
  }) {
    return IngressInfo._(
      ingressTypeId: ingressTypeId ?? this.ingressTypeId,
      originName: originName != null ? originName() : this.originName,
      originContact: originContact != null ? originContact() : this.originContact,
      serviceReason: serviceReason ?? this.serviceReason,
      linkedSocialPrograms: linkedSocialPrograms ?? this.linkedSocialPrograms,
    );
  }

  static Result<IngressInfo> create({
    required LookupId ingressTypeId, String? originName, String? originContact, required String? serviceReason, required List<ProgramLink> linkedSocialPrograms
  }) {
    final reason = serviceReason?.normalizedTrim();
    if (reason == null || reason.isEmpty) {
      return Failure(
        AppError(code: 'ING-001', message: 'Motivo do atendimento não pode ser vazio', module: 'social-care/ingress-info', kind: 'domainValidation', http: 422, observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.warning))
      );
    }

    return Success(IngressInfo._(
      ingressTypeId: ingressTypeId,
      originName: originName?.nullIfEmptyTrimmed(),
      originContact: originContact?.nullIfEmptyTrimmed(),
      serviceReason: reason,
      linkedSocialPrograms: List.unmodifiable(linkedSocialPrograms),
    ));
  }
}

// =============================================================================
// APPOINTMENT
// =============================================================================

enum AppointmentType { homeVisit, officeAppointment, phoneCall, multidisciplinary, other }

final class SocialCareAppointment with Equatable {
  const SocialCareAppointment._({
    required this.id, required this.date, required this.professionalInChargeId, required this.type, this.summary, this.actionPlan
  });

  final AppointmentId id;
  final TimeStamp date;
  final ProfessionalId professionalInChargeId;
  final AppointmentType type;
  final String? summary;
  final String? actionPlan;

  @override
  List<Object?> get props => [id]; // Igualdade apenas pelo ID conforme o design

  SocialCareAppointment copyWith({
    AppointmentId? id,
    TimeStamp? date,
    ProfessionalId? professionalInChargeId,
    AppointmentType? type,
    String? Function()? summary,
    String? Function()? actionPlan,
  }) {
    return SocialCareAppointment._(
      id: id ?? this.id,
      date: date ?? this.date,
      professionalInChargeId: professionalInChargeId ?? this.professionalInChargeId,
      type: type ?? this.type,
      summary: summary != null ? summary() : this.summary,
      actionPlan: actionPlan != null ? actionPlan() : this.actionPlan,
    );
  }

  static Result<SocialCareAppointment> create({
    required AppointmentId id, required TimeStamp date, required ProfessionalId professionalInChargeId, required AppointmentType type, String? summary, String? actionPlan, TimeStamp? now
  }) {
    final refNow = now ?? TimeStamp.now;
    if (date.date.isAfter(refNow.date)) {
      return Failure(_buildApptError('SCA-001', 'Data do atendimento não pode ser no futuro'));
    }

    final s = summary?.nullIfEmptyTrimmed();
    final ap = actionPlan?.nullIfEmptyTrimmed();

    if (s == null && ap == null) {
      return Failure(_buildApptError('SCA-003', "Pelo menos um dos campos 'resumo' ou 'plano de ação' deve ser preenchido")); // Adjusted code SCA-002 -> SCA-003 in logic
    }

    if (s != null && s.length > 500) return Failure(_buildApptError('SCA-004', 'Resumo não pode exceder 500 caracteres'));
    if (ap != null && ap.length > 2000) return Failure(_buildApptError('SCA-005', 'Plano de ação não pode exceder 2000 caracteres'));

    return Success(SocialCareAppointment._(id: id, date: date, professionalInChargeId: professionalInChargeId, type: type, summary: s, actionPlan: ap));
  }

  static AppError _buildApptError(String code, String message) {
    return AppError(code: code, message: message, module: 'social-care/appointment', kind: 'domainValidation', http: 422, observability: const Observability(category: ErrorCategory.domainRuleViolation, severity: ErrorSeverity.warning));
  }
}
