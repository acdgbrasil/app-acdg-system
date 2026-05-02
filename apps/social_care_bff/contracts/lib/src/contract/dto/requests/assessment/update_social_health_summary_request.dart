import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_social_health_summary_request.g.dart';

@JsonSerializable()
class UpdateSocialHealthSummaryRequest with Equatable {
  const UpdateSocialHealthSummaryRequest({
    required this.requiresConstantCare,
    required this.hasMobilityImpairment,
    required this.hasRelevantDrugTherapy,
    this.functionalDependencies = const [],
  });

  factory UpdateSocialHealthSummaryRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$UpdateSocialHealthSummaryRequestFromJson(json);

  final bool requiresConstantCare;
  final bool hasMobilityImpairment;
  final bool hasRelevantDrugTherapy;
  final List<String> functionalDependencies;

  Map<String, dynamic> toJson() =>
      _$UpdateSocialHealthSummaryRequestToJson(this);

  @override
  List<Object?> get props => [
    requiresConstantCare,
    hasMobilityImpairment,
    hasRelevantDrugTherapy,
    functionalDependencies,
  ];
}
