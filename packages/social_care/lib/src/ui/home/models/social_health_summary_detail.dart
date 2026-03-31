final class SocialHealthSummaryDetail {
  final bool requiresConstantCare;
  final bool hasMobilityImpairment;
  final bool hasRelevantDrugTherapy;
  final List<String> functionalDependencies;

  const SocialHealthSummaryDetail({
    required this.requiresConstantCare,
    required this.hasMobilityImpairment,
    required this.hasRelevantDrugTherapy,
    required this.functionalDependencies,
  });

  factory SocialHealthSummaryDetail.fromJson(Map<String, dynamic> json) {
    return SocialHealthSummaryDetail(
      requiresConstantCare: json['requiresConstantCare'] as bool,
      hasMobilityImpairment: json['hasMobilityImpairment'] as bool,
      hasRelevantDrugTherapy: json['hasRelevantDrugTherapy'] as bool,
      functionalDependencies: (json['functionalDependencies'] as List)
          .map((e) => e as String)
          .toList(),
    );
  }
}
