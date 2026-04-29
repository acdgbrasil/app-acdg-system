import 'package:core_contracts/core_contracts.dart';
import '../../utils/app_error.dart';
import '../../utils/string_helpers.dart';

/// Expressão regular para validação estrita de UUID v4.
final _uuidRegex = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

AppError _uuidError(String code, String module, String? raw) {
  return AppError(
    code: code,
    message:
        "O valor fornecido ('${raw ?? 'null'}') não é um identificador válido.",
    module: module,
    kind: 'invalidFormat',
    http: 422,
    observability: const Observability(
      category: ErrorCategory.domainRuleViolation,
      severity: ErrorSeverity.error,
    ),
  );
}

// =============================================================================
// KERNEL IDs
// =============================================================================

extension type const PersonId._(String value) {
  /// Factory validadora — retorna Success(PersonId) ou Failure AppError.
  static Result<PersonId> create(String? rawValue) {
    final normalized = rawValue?.normalizedTrim().toLowerCase();
    if (normalized == null ||
        normalized.isEmpty ||
        !_uuidRegex.hasMatch(normalized)) {
      return Failure(
        _uuidError('PID-001', 'social-care/person-id', rawValue),
      );
    }
    return Success(PersonId._(normalized));
  }

  /// Constructor para origens garantidas (UUID.v4(), fixtures). Zero-cost.
  const PersonId.trusted(String value) : this._(value);
}

extension type const ProfessionalId._(String value) {
  static Result<ProfessionalId> create(String? rawValue) {
    final normalized = rawValue?.normalizedTrim().toLowerCase();
    if (normalized == null ||
        normalized.isEmpty ||
        !_uuidRegex.hasMatch(normalized)) {
      return Failure(
        _uuidError('PRI-001', 'social-care/professional-id', rawValue),
      );
    }
    return Success(ProfessionalId._(normalized));
  }

  const ProfessionalId.trusted(String value) : this._(value);
}

extension type const PatientId._(String value) {
  static Result<PatientId> create(String? rawValue) {
    final normalized = rawValue?.normalizedTrim().toLowerCase();
    if (normalized == null ||
        normalized.isEmpty ||
        !_uuidRegex.hasMatch(normalized)) {
      return Failure(
        _uuidError('PAI-001', 'social-care/patient-id', rawValue),
      );
    }
    return Success(PatientId._(normalized));
  }

  const PatientId.trusted(String value) : this._(value);
}

extension type const LookupId._(String value) {
  static Result<LookupId> create(String? rawValue) {
    final normalized = rawValue?.normalizedTrim().toLowerCase();
    if (normalized == null ||
        normalized.isEmpty ||
        !_uuidRegex.hasMatch(normalized)) {
      return Failure(
        _uuidError('LID-001', 'social-care/lookup-id', rawValue),
      );
    }
    return Success(LookupId._(normalized));
  }

  const LookupId.trusted(String value) : this._(value);
}

// =============================================================================
// CARE & PROTECTION IDs
// =============================================================================

extension type const AppointmentId._(String value) {
  static Result<AppointmentId> create(String? rawValue) {
    final normalized = rawValue?.normalizedTrim().toLowerCase();
    if (normalized == null ||
        normalized.isEmpty ||
        !_uuidRegex.hasMatch(normalized)) {
      return Failure(
        _uuidError('AI-001', 'social-care/appointment-id', rawValue),
      );
    }
    return Success(AppointmentId._(normalized));
  }

  const AppointmentId.trusted(String value) : this._(value);
}

extension type const ReferralId._(String value) {
  static Result<ReferralId> create(String? rawValue) {
    final normalized = rawValue?.normalizedTrim().toLowerCase();
    if (normalized == null ||
        normalized.isEmpty ||
        !_uuidRegex.hasMatch(normalized)) {
      return Failure(
        _uuidError('RI-001', 'social-care/referral-id', rawValue),
      );
    }
    return Success(ReferralId._(normalized));
  }

  const ReferralId.trusted(String value) : this._(value);
}

extension type const ViolationReportId._(String value) {
  static Result<ViolationReportId> create(String? rawValue) {
    final normalized = rawValue?.normalizedTrim().toLowerCase();
    if (normalized == null ||
        normalized.isEmpty ||
        !_uuidRegex.hasMatch(normalized)) {
      return Failure(
        _uuidError('VRI-001', 'social-care/violation-report-id', rawValue),
      );
    }
    return Success(ViolationReportId._(normalized));
  }

  const ViolationReportId.trusted(String value) : this._(value);
}
