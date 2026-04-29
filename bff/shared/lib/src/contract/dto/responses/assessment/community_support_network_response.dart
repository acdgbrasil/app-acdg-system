import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'community_support_network_response.g.dart';

@JsonSerializable()
class CommunitySupportNetworkResponse with Equatable {
  const CommunitySupportNetworkResponse({
    required this.hasRelativeSupport,
    required this.hasNeighborSupport,
    required this.familyConflicts,
    required this.patientParticipatesInGroups,
    required this.familyParticipatesInGroups,
    required this.patientHasAccessToLeisure,
    required this.facesDiscrimination,
  });

  factory CommunitySupportNetworkResponse.fromJson(Map<String, dynamic> json) =>
      _$CommunitySupportNetworkResponseFromJson(json);

  final bool hasRelativeSupport;
  final bool hasNeighborSupport;
  final String familyConflicts;
  final bool patientParticipatesInGroups;
  final bool familyParticipatesInGroups;
  final bool patientHasAccessToLeisure;
  final bool facesDiscrimination;

  Map<String, dynamic> toJson() =>
      _$CommunitySupportNetworkResponseToJson(this);

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
}
