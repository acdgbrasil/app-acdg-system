final class PlacementHistoryDetail {
  final List<IndividualPlacementDetail> individualPlacements;
  final String? homeLossReport;
  final String? thirdPartyGuardReport;
  final bool adultInPrison;
  final bool adolescentInInternment;

  const PlacementHistoryDetail({
    required this.individualPlacements,
    this.homeLossReport,
    this.thirdPartyGuardReport,
    required this.adultInPrison,
    required this.adolescentInInternment,
  });

  factory PlacementHistoryDetail.fromJson(Map<String, dynamic> json) {
    return PlacementHistoryDetail(
      individualPlacements: (json['individualPlacements'] as List)
          .map(
            (e) =>
                IndividualPlacementDetail.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      homeLossReport: json['homeLossReport'] as String?,
      thirdPartyGuardReport: json['thirdPartyGuardReport'] as String?,
      adultInPrison: json['adultInPrison'] as bool,
      adolescentInInternment: json['adolescentInInternment'] as bool,
    );
  }
}

final class IndividualPlacementDetail {
  final String id;
  final String memberId;
  final String startDate;
  final String? endDate;
  final String reason;

  const IndividualPlacementDetail({
    required this.id,
    required this.memberId,
    required this.startDate,
    this.endDate,
    required this.reason,
  });

  factory IndividualPlacementDetail.fromJson(Map<String, dynamic> json) {
    return IndividualPlacementDetail(
      id: json['id'] as String,
      memberId: json['memberId'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String?,
      reason: json['reason'] as String,
    );
  }
}
