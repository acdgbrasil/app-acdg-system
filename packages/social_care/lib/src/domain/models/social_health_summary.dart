import 'package:core/core.dart';

/// Summary of the social/health status of a patient (ficha Resumo).
class SocialHealthSummary with Equatable {
  const SocialHealthSummary({
    required this.requiresConstantCare,
    required this.hasMobilityImpairment,
    required this.hasRelevantDrugTherapy,
    this.functionalDependencies = const [],
  });

  final bool requiresConstantCare;
  final bool hasMobilityImpairment;
  final bool hasRelevantDrugTherapy;
  final List<String> functionalDependencies;

  SocialHealthSummary copyWith({
    bool? requiresConstantCare,
    bool? hasMobilityImpairment,
    bool? hasRelevantDrugTherapy,
    List<String>? functionalDependencies,
  }) {
    return SocialHealthSummary(
      requiresConstantCare: requiresConstantCare ?? this.requiresConstantCare,
      hasMobilityImpairment:
          hasMobilityImpairment ?? this.hasMobilityImpairment,
      hasRelevantDrugTherapy:
          hasRelevantDrugTherapy ?? this.hasRelevantDrugTherapy,
      functionalDependencies:
          functionalDependencies ?? this.functionalDependencies,
    );
  }

  @override
  List<Object?> get props => [
    requiresConstantCare,
    hasMobilityImpairment,
    hasRelevantDrugTherapy,
    functionalDependencies,
  ];
}
