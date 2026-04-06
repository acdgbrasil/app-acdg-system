import 'package:core_contracts/core_contracts.dart';
import '../../utils/app_error.dart';
import '../../utils/string_helpers.dart';

final class CommunitySupportNetwork with Equatable {
  const CommunitySupportNetwork._({
    required this.hasRelativeSupport,
    required this.hasNeighborSupport,
    required this.familyConflicts,
    required this.patientParticipatesInGroups,
    required this.familyParticipatesInGroups,
    required this.patientHasAccessToLeisure,
    required this.facesDiscrimination,
  });

  final bool hasRelativeSupport;
  final bool hasNeighborSupport;
  final String familyConflicts;
  final bool patientParticipatesInGroups;
  final bool familyParticipatesInGroups;
  final bool patientHasAccessToLeisure;
  final bool facesDiscrimination;

  @override
  List<Object?> get props => [
    hasRelativeSupport,
    hasNeighborSupport,
    familyConflicts,
    patientParticipatesInGroups,
    familyParticipatesInGroups,
    patientHasAccessToLeisure,
    facesDiscrimination,
  ];

  static Result<CommunitySupportNetwork> create({
    required bool hasRelativeSupport,
    required bool hasNeighborSupport,
    required String? familyConflicts,
    required bool patientParticipatesInGroups,
    required bool familyParticipatesInGroups,
    required bool patientHasAccessToLeisure,
    required bool facesDiscrimination,
  }) {
    final conflicts = familyConflicts?.normalizedTrim() ?? '';

    // According to rule: if not empty, it can't be whitespace only (already handled by trim)
    // But if they provided "   " it becomes "" which might be fine if it's optional?
    // Wait, familyConflicts is required in yaml: type: string, required: true. So it can't be null.
    // If it's required and they pass just whitespace, it fails.
    if (familyConflicts != null &&
        conflicts.isEmpty &&
        familyConflicts.trim().isEmpty &&
        familyConflicts.isNotEmpty) {
      return Failure(
        _buildError(
          'CSN-001',
          'Conflitos familiares não pode conter apenas espaços em branco',
        ),
      );
    }

    if (conflicts.length > 300) {
      return Failure(
        _buildError(
          'CSN-002',
          'Conflitos familiares não pode exceder 300 caracteres',
        ),
      );
    }

    return Success(
      CommunitySupportNetwork._(
        hasRelativeSupport: hasRelativeSupport,
        hasNeighborSupport: hasNeighborSupport,
        familyConflicts: conflicts,
        patientParticipatesInGroups: patientParticipatesInGroups,
        familyParticipatesInGroups: familyParticipatesInGroups,
        patientHasAccessToLeisure: patientHasAccessToLeisure,
        facesDiscrimination: facesDiscrimination,
      ),
    );
  }

  static AppError _buildError(String code, String message) {
    return AppError(
      code: code,
      message: message,
      module: 'social-care/community-support',
      kind: 'domainValidation',
      http: 422,
      observability: const Observability(
        category: ErrorCategory.domainRuleViolation,
        severity: ErrorSeverity.warning,
      ),
    );
  }
}
