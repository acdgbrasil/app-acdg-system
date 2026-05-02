import 'package:core_contracts/core_contracts.dart';
import '../../utils/app_error.dart';
import '../../utils/string_helpers.dart';

final class SocialHealthSummary with Equatable {
  const SocialHealthSummary._({
    required this.requiresConstantCare,
    required this.hasMobilityImpairment,
    required this.functionalDependencies,
    required this.hasRelevantDrugTherapy,
  });

  final bool requiresConstantCare;
  final bool hasMobilityImpairment;
  final List<String> functionalDependencies;
  final bool hasRelevantDrugTherapy;

  @override
  List<Object?> get props => [
    requiresConstantCare,
    hasMobilityImpairment,
    functionalDependencies,
    hasRelevantDrugTherapy,
  ];

  static Result<SocialHealthSummary> create({
    required bool requiresConstantCare,
    required bool hasMobilityImpairment,
    required List<String> functionalDependencies,
    required bool hasRelevantDrugTherapy,
  }) {
    // Normalization: trim each, remove empty, deduplicate preserving order
    final normalizedList = <String>[];
    for (final item in functionalDependencies) {
      final trimmed = item.normalizedTrim();
      if (trimmed.isEmpty) {
        return Failure(
          AppError(
            code: 'SHS-001',
            message: 'Itens de dependência funcional não podem ser vazios',
            module: 'social-care/social-health-summary',
            kind: 'domainValidation',
            http: 422,
            observability: const Observability(
              category: ErrorCategory.domainRuleViolation,
              severity: ErrorSeverity.warning,
            ),
          ),
        );
      }
      if (!normalizedList.contains(trimmed)) {
        normalizedList.add(trimmed);
      }
    }

    return Success(
      SocialHealthSummary._(
        requiresConstantCare: requiresConstantCare,
        hasMobilityImpairment: hasMobilityImpairment,
        functionalDependencies: List.unmodifiable(normalizedList),
        hasRelevantDrugTherapy: hasRelevantDrugTherapy,
      ),
    );
  }
}
