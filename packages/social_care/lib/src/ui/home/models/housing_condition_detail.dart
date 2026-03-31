final class HousingConditionDetail {
  final String type;
  final String wallMaterial;
  final String waterSupply;
  final String electricityAccess;
  final String sewageDisposal;
  final String wasteCollection;
  final String accessibilityLevel;
  final int numberOfRooms;
  final int numberOfBedrooms;
  final int numberOfBathrooms;
  final bool hasPipedWater;
  final bool isInGeographicRiskArea;
  final bool hasDifficultAccess;
  final bool isInSocialConflictArea;
  final bool hasDiagnosticObservations;

  const HousingConditionDetail({
    required this.type,
    required this.wallMaterial,
    required this.waterSupply,
    required this.electricityAccess,
    required this.sewageDisposal,
    required this.wasteCollection,
    required this.accessibilityLevel,
    required this.numberOfRooms,
    required this.numberOfBedrooms,
    required this.numberOfBathrooms,
    required this.hasPipedWater,
    required this.isInGeographicRiskArea,
    required this.hasDifficultAccess,
    required this.isInSocialConflictArea,
    required this.hasDiagnosticObservations,
  });

  factory HousingConditionDetail.fromJson(Map<String, dynamic> json) {
    return HousingConditionDetail(
      type: json['type'] as String,
      wallMaterial: json['wallMaterial'] as String,
      waterSupply: json['waterSupply'] as String,
      electricityAccess: json['electricityAccess'] as String,
      sewageDisposal: json['sewageDisposal'] as String,
      wasteCollection: json['wasteCollection'] as String,
      accessibilityLevel: json['accessibilityLevel'] as String,
      numberOfRooms: json['numberOfRooms'] as int,
      numberOfBedrooms: json['numberOfBedrooms'] as int,
      numberOfBathrooms: json['numberOfBathrooms'] as int,
      hasPipedWater: json['hasPipedWater'] as bool,
      isInGeographicRiskArea: json['isInGeographicRiskArea'] as bool,
      hasDifficultAccess: json['hasDifficultAccess'] as bool,
      isInSocialConflictArea: json['isInSocialConflictArea'] as bool,
      hasDiagnosticObservations: json['hasDiagnosticObservations'] as bool,
    );
  }
}
