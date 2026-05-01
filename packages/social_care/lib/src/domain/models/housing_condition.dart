import 'package:core/core.dart';

/// Housing condition assessment (ficha Habitação).
class HousingCondition with Equatable {
  const HousingCondition({
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

  HousingCondition copyWith({
    String? type,
    String? wallMaterial,
    int? numberOfRooms,
    int? numberOfBedrooms,
    int? numberOfBathrooms,
    String? waterSupply,
    bool? hasPipedWater,
    String? electricityAccess,
    String? sewageDisposal,
    String? wasteCollection,
    String? accessibilityLevel,
    bool? isInGeographicRiskArea,
    bool? hasDifficultAccess,
    bool? isInSocialConflictArea,
    bool? hasDiagnosticObservations,
  }) {
    return HousingCondition(
      type: type ?? this.type,
      wallMaterial: wallMaterial ?? this.wallMaterial,
      numberOfRooms: numberOfRooms ?? this.numberOfRooms,
      numberOfBedrooms: numberOfBedrooms ?? this.numberOfBedrooms,
      numberOfBathrooms: numberOfBathrooms ?? this.numberOfBathrooms,
      waterSupply: waterSupply ?? this.waterSupply,
      hasPipedWater: hasPipedWater ?? this.hasPipedWater,
      electricityAccess: electricityAccess ?? this.electricityAccess,
      sewageDisposal: sewageDisposal ?? this.sewageDisposal,
      wasteCollection: wasteCollection ?? this.wasteCollection,
      accessibilityLevel: accessibilityLevel ?? this.accessibilityLevel,
      isInGeographicRiskArea:
          isInGeographicRiskArea ?? this.isInGeographicRiskArea,
      hasDifficultAccess: hasDifficultAccess ?? this.hasDifficultAccess,
      isInSocialConflictArea:
          isInSocialConflictArea ?? this.isInSocialConflictArea,
      hasDiagnosticObservations:
          hasDiagnosticObservations ?? this.hasDiagnosticObservations,
    );
  }

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
