import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'social_health_summary_response.g.dart';

@JsonSerializable()
class SocialHealthSummaryResponse with Equatable {
  const SocialHealthSummaryResponse({
    required this.requiresConstantCare,
    required this.hasMobilityImpairment,
    required this.hasRelevantDrugTherapy,
    this.functionalDependencies = const [],
  });

  factory SocialHealthSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$SocialHealthSummaryResponseFromJson(json);

  final bool requiresConstantCare;
  final bool hasMobilityImpairment;
  final bool hasRelevantDrugTherapy;
  final List<String> functionalDependencies;

  Map<String, dynamic> toJson() => _$SocialHealthSummaryResponseToJson(this);

  @override
  List<Object?> get props => [
    requiresConstantCare,
    hasMobilityImpairment,
    hasRelevantDrugTherapy,
    functionalDependencies,
  ];
}
