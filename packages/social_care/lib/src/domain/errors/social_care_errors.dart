import 'package:equatable/equatable.dart';

/// Sealed class representing all possible domain errors in the Social Care module.
///
/// Each subtype carries a user-facing message via [toString] so the UI
/// can display it directly without interpreting error internals.
sealed class SocialCareError extends Equatable implements Exception {
  const SocialCareError();

  @override
  List<Object?> get props => [];
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
  List<Object?> get props => [id];

  @override
  String toString() => 'Paciente não encontrado: $id';
}

final class InvalidDataError extends PatientError {
  const InvalidDataError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];

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
  List<Object?> get props => [message];

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
// INFRASTRUCTURE ERRORS
// =============================================================================

/// Thrown when a real network failure occurs (no connectivity, timeout, DNS).
///
/// Only for actual transport-layer failures — NOT for HTTP error responses.
final class NetworkError extends SocialCareError {
  const NetworkError(this.technicalDetail);
  final String technicalDetail;

  @override
  List<Object?> get props => [technicalDetail];

  @override
  String toString() => 'Sem conexão com o servidor. Verifique sua internet.';
}

/// Thrown when the server returns an error response (4xx/5xx) that doesn't
/// map to a known domain error.
///
/// Carries the backend message so the UI can display something meaningful
/// instead of a generic fallback.
final class ServerError extends SocialCareError {
  const ServerError({
    required this.httpStatus,
    required this.backendCode,
    required this.backendMessage,
  });

  final int httpStatus;
  final String backendCode;
  final String backendMessage;

  @override
  List<Object?> get props => [httpStatus, backendCode, backendMessage];

  @override
  String toString() => backendMessage.isNotEmpty
      ? backendMessage
      : 'Erro no servidor (código $backendCode). Tente novamente.';
}

/// Fallback for unexpected system failures (programming errors, null access, etc.).
final class UnexpectedSocialCareError extends SocialCareError {
  const UnexpectedSocialCareError(this.error);
  final Object error;

  @override
  List<Object?> get props => [error];

  @override
  String toString() =>
      'Ocorreu um erro inesperado. Tente novamente mais tarde.';
}
