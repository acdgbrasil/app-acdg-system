import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_housing_condition_request.g.dart';

@JsonSerializable()
class UpdateHousingConditionRequest with Equatable {
  const UpdateHousingConditionRequest({
    required this.type,
    required this.wallMaterial,
    required this.numberOfRooms,
    required this.numberOfBedrooms,
    required this.numberOfBathrooms,
    required this.waterSupply,
    required this.hasPipedWater,
    required this.electricityAccess,
    required this.sewageDisposal,
    required this.wasteCollection,
    required this.accessibilityLevel,
    required this.isInGeographicRiskArea,
    required this.hasDifficultAccess,
    required this.isInSocialConflictArea,
    required this.hasDiagnosticObservations,
  });

  factory UpdateHousingConditionRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateHousingConditionRequestFromJson(json);

  final String type;
  final String wallMaterial;
  final int numberOfRooms;
  final int numberOfBedrooms;
  final int numberOfBathrooms;
  final String waterSupply;
  final bool hasPipedWater;
  final String electricityAccess;
  final String sewageDisposal;
  final String wasteCollection;
  final String accessibilityLevel;
  final bool isInGeographicRiskArea;
  final bool hasDifficultAccess;
  final bool isInSocialConflictArea;
  final bool hasDiagnosticObservations;

  Map<String, dynamic> toJson() => _$UpdateHousingConditionRequestToJson(this);

  @override
  List<Object?> get props => [
    type,
    wallMaterial,
    numberOfRooms,
    numberOfBedrooms,
    numberOfBathrooms,
    waterSupply,
    hasPipedWater,
    electricityAccess,
    sewageDisposal,
    wasteCollection,
    accessibilityLevel,
    isInGeographicRiskArea,
    hasDifficultAccess,
    isInSocialConflictArea,
    hasDiagnosticObservations,
  ];
}
