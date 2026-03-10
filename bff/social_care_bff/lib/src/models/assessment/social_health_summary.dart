/// Social health summary assessment data.
final class SocialHealthSummary {
  const SocialHealthSummary({
    required this.requiresConstantCare,
    required this.hasMobilityImpairment,
    required this.functionalDependencies,
    required this.hasRelevantDrugTherapy,
  });

  final bool requiresConstantCare;
  final bool hasMobilityImpairment;
  final List<String> functionalDependencies;
  final bool hasRelevantDrugTherapy;
}
