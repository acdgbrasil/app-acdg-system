import 'package:core/core.dart';
import '../../utils/app_error.dart';
import '../../utils/string_helpers.dart';

/// Expressão regular para validação estrita de UUID v4.
final _uuidRegex = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

/// Classe base para Value Objects baseados em UUID.
abstract class BaseUuid with Equatable {
  const BaseUuid(this.value);
  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

/// Validador comum para IDs.
Result<String> _validateUuid(String? rawValue, String code, String module) {
  final normalized = rawValue?.normalizedTrim().toLowerCase();

  if (normalized == null ||
      normalized.isEmpty ||
      !_uuidRegex.hasMatch(normalized)) {
    return Failure(
      AppError(
        code: code,
        message:
            "O valor fornecido ('${rawValue ?? 'null'}') não é um identificador válido.",
        module: module,
        kind: 'invalidFormat',
        http: 422,
        observability: const Observability(
          category: ErrorCategory.domainRuleViolation,
          severity: ErrorSeverity.error,
        ),
      ),
    );
  }
  return Success(normalized);
}

// =============================================================================
// KERNEL IDs
// =============================================================================

final class PersonId extends BaseUuid {
  const PersonId._(super.value);

  static Result<PersonId> create(String? rawValue) {
    return _validateUuid(
      rawValue,
      'PID-001',
      'social-care/person-id',
    ).map(PersonId._);
  }
}

final class ProfessionalId extends BaseUuid {
  const ProfessionalId._(super.value);

  static Result<ProfessionalId> create(String? rawValue) {
    return _validateUuid(
      rawValue,
      'PRI-001',
      'social-care/professional-id',
    ).map(ProfessionalId._);
  }
}

final class PatientId extends BaseUuid {
  const PatientId._(super.value);

  static Result<PatientId> create(String? rawValue) {
    return _validateUuid(
      rawValue,
      'PAI-001',
      'social-care/patient-id',
    ).map(PatientId._);
  }
}

final class LookupId extends BaseUuid {
  const LookupId._(super.value);

  static Result<LookupId> create(String? rawValue) {
    return _validateUuid(
      rawValue,
      'LID-001',
      'social-care/lookup-id',
    ).map(LookupId._);
  }
}

// =============================================================================
// CARE & PROTECTION IDs
// =============================================================================

final class AppointmentId extends BaseUuid {
  const AppointmentId._(super.value);

  static Result<AppointmentId> create(String? rawValue) {
    return _validateUuid(
      rawValue,
      'AI-001',
      'social-care/appointment-id',
    ).map(AppointmentId._);
  }
}

final class ReferralId extends BaseUuid {
  const ReferralId._(super.value);

  static Result<ReferralId> create(String? rawValue) {
    return _validateUuid(
      rawValue,
      'RI-001',
      'social-care/referral-id',
    ).map(ReferralId._);
  }
}

final class ViolationReportId extends BaseUuid {
  const ViolationReportId._(super.value);

  static Result<ViolationReportId> create(String? rawValue) {
    return _validateUuid(
      rawValue,
      'VRI-001',
      'social-care/violation-report-id',
    ).map(ViolationReportId._);
  }
}
