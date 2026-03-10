/// Institutional placement history for a patient.
final class PlacementHistory {
  const PlacementHistory({
    required this.individualPlacements,
    this.homeLossReport,
    this.thirdPartyGuardReport,
    this.adultInPrison,
    this.adolescentInInternment,
  });

  final List<PlacementRegistry> individualPlacements;
  final String? homeLossReport;
  final String? thirdPartyGuardReport;
  final bool? adultInPrison;
  final bool? adolescentInInternment;
}

/// A single placement entry for a family member.
final class PlacementRegistry {
  const PlacementRegistry({
    required this.id,
    required this.memberId,
    required this.reason,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String memberId;
  final String reason;
  final DateTime? startDate;
  final DateTime? endDate;
}
