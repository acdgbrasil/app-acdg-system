import 'package:core/core.dart';

/// History of placements (foster care, institutional custody, etc.) of the
/// patient's household.
class PlacementHistory with Equatable {
  const PlacementHistory({
    this.individualPlacements = const [],
    this.homeLossReport,
    this.thirdPartyGuardReport,
    this.adultInPrison = false,
    this.adolescentInInternment = false,
  });

  final List<PlacementEntry> individualPlacements;
  final String? homeLossReport;
  final String? thirdPartyGuardReport;
  final bool adultInPrison;
  final bool adolescentInInternment;

  PlacementHistory copyWith({
    List<PlacementEntry>? individualPlacements,
    String? homeLossReport,
    String? thirdPartyGuardReport,
    bool? adultInPrison,
    bool? adolescentInInternment,
  }) {
    return PlacementHistory(
      individualPlacements: individualPlacements ?? this.individualPlacements,
      homeLossReport: homeLossReport ?? this.homeLossReport,
      thirdPartyGuardReport:
          thirdPartyGuardReport ?? this.thirdPartyGuardReport,
      adultInPrison: adultInPrison ?? this.adultInPrison,
      adolescentInInternment:
          adolescentInInternment ?? this.adolescentInInternment,
    );
  }

  @override
  List<Object?> get props => [
    individualPlacements,
    homeLossReport,
    thirdPartyGuardReport,
    adultInPrison,
    adolescentInInternment,
  ];
}

/// Single placement entry describing where and when a member was placed.
class PlacementEntry with Equatable {
  const PlacementEntry({
    required this.entryId,
    required this.memberId,
    required this.startDate,
    required this.reason,
    this.endDate,
  });

  final String entryId;
  final String memberId;
  final String startDate;
  final String reason;
  final String? endDate;

  PlacementEntry copyWith({
    String? entryId,
    String? memberId,
    String? startDate,
    String? reason,
    String? endDate,
  }) {
    return PlacementEntry(
      entryId: entryId ?? this.entryId,
      memberId: memberId ?? this.memberId,
      startDate: startDate ?? this.startDate,
      reason: reason ?? this.reason,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [entryId, memberId, startDate, reason, endDate];
}
