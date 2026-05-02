import 'dart:math';

/// Service for calculating housing related indicators.
abstract final class HousingAnalyticsService {
  /// Calculates housing density: total members / number of bedrooms.
  /// Minimum value for both is 1 to avoid division by zero.
  static double calculateDensity({
    required int totalFamilyMembers,
    required int numberOfBedrooms,
  }) {
    final memberCount = max(totalFamilyMembers, 1);
    final bedroomCount = max(numberOfBedrooms, 1);
    return memberCount / bedroomCount;
  }

  /// Determines if a household is overcrowded (density > 3.0).
  static bool isOvercrowded({
    required int totalFamilyMembers,
    required int numberOfBedrooms,
  }) {
    return calculateDensity(
          totalFamilyMembers: totalFamilyMembers,
          numberOfBedrooms: numberOfBedrooms,
        ) >
        3.0;
  }
}
