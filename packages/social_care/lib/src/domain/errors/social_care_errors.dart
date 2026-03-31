/// Sealed class representing all possible domain errors in the Social Care module.
sealed class SocialCareError implements Exception {
  const SocialCareError();
}

// =============================================================================
// REGISTRY & PATIENT ERRORS
// =============================================================================

/// Thrown during registration or updates of patient data.
sealed class PatientError extends SocialCareError {
  const PatientError();
}

final class DuplicatePatientError extends PatientError {
  const DuplicatePatientError();
  @override
  String toString() => 'Este paciente já se encontra registrado no sistema.';
}

final class PatientNotFoundError extends PatientError {
  const PatientNotFoundError(this.id);
  final String id;
  @override
  String toString() => 'Paciente não encontrado: $id';
}

final class InvalidDataError extends PatientError {
  const InvalidDataError(this.message);
  final String message;
  @override
  String toString() => 'Dados inválidos: $message';
}

// =============================================================================
// ASSESSMENT ERRORS
// =============================================================================

/// Thrown during assessments (Housing, Socioeconomic, etc.).
sealed class AssessmentError extends SocialCareError {
  const AssessmentError();
}

final class InconsistentAssessmentError extends AssessmentError {
  const InconsistentAssessmentError(this.message);
  final String message;
  @override
  String toString() => 'Inconsistência na avaliação: $message';
}

// =============================================================================
// FAMILY ERRORS
// =============================================================================

/// Thrown during family composition management.
sealed class FamilyError extends SocialCareError {
  const FamilyError();
}

final class MultiplePrimaryReferencesError extends FamilyError {
  const MultiplePrimaryReferencesError();
  @override
  String toString() => 'Não é permitido mais de uma Pessoa de Referência (PR).';
}

final class PrMemberRequiredError extends FamilyError {
  const PrMemberRequiredError();
  @override
  String toString() => 'É necessário exatamente uma Pessoa de Referência (PR).';
}

// =============================================================================
// INFRASTRUCTURE & GENERIC ERRORS
// =============================================================================

/// Thrown when the backend or network fails.
final class NetworkSocialCareError extends SocialCareError {
  const NetworkSocialCareError(this.technicalMessage);
  final String technicalMessage;
  @override
  String toString() => 'Erro de conexão. Verifique sua internet.';
}

/// Fallback for unexpected system failures.
final class UnexpectedSocialCareError extends SocialCareError {
  const UnexpectedSocialCareError(this.error);
  final Object error;
  @override
  String toString() =>
      'Ocorreu um erro inesperado. Tente novamente mais tarde.';
}
