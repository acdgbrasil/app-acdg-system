import 'package:json_annotation/json_annotation.dart';

part 'placement_history_response.g.dart';

@JsonSerializable()
class PlacementHistoryResponse {
  const PlacementHistoryResponse({
    this.individualPlacements = const [],
    this.homeLossReport,
    this.thirdPartyGuardReport,
    this.adultInPrison = false,
    this.adolescentInInternment = false,
  });

  factory PlacementHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$PlacementHistoryResponseFromJson(json);

  final List<PlacementRegistryResponse> individualPlacements;
  final String? homeLossReport;
  final String? thirdPartyGuardReport;
  final bool adultInPrison;
  final bool adolescentInInternment;

  Map<String, dynamic> toJson() => _$PlacementHistoryResponseToJson(this);
}

@JsonSerializable()
class PlacementRegistryResponse {
  const PlacementRegistryResponse({
    required this.id,
    required this.memberId,
    required this.startDate,
    required this.reason,
    this.endDate,
  });

  factory PlacementRegistryResponse.fromJson(Map<String, dynamic> json) =>
      _$PlacementRegistryResponseFromJson(json);

  final String id;
  final String memberId;
  final String startDate;
  final String? endDate;
  final String reason;

  Map<String, dynamic> toJson() => _$PlacementRegistryResponseToJson(this);
}
