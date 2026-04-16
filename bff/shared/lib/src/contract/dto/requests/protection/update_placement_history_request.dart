import 'package:json_annotation/json_annotation.dart';

part 'update_placement_history_request.g.dart';

@JsonSerializable()
class UpdatePlacementHistoryRequest {
  const UpdatePlacementHistoryRequest({
    this.registries = const [],
    this.collectiveSituations,
    this.separationChecklist,
  });

  factory UpdatePlacementHistoryRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdatePlacementHistoryRequestFromJson(json);

  final List<RegistryDraftDto> registries;
  final CollectiveDraftDto? collectiveSituations;
  final SeparationDraftDto? separationChecklist;

  Map<String, dynamic> toJson() => _$UpdatePlacementHistoryRequestToJson(this);
}

@JsonSerializable()
class RegistryDraftDto {
  const RegistryDraftDto({
    required this.memberId,
    required this.startDate,
    required this.reason,
    this.endDate,
  });

  factory RegistryDraftDto.fromJson(Map<String, dynamic> json) =>
      _$RegistryDraftDtoFromJson(json);

  final String memberId;
  final String startDate;
  final String? endDate;
  final String reason;

  Map<String, dynamic> toJson() => _$RegistryDraftDtoToJson(this);
}

@JsonSerializable()
class CollectiveDraftDto {
  const CollectiveDraftDto({this.homeLossReport, this.thirdPartyGuardReport});

  factory CollectiveDraftDto.fromJson(Map<String, dynamic> json) =>
      _$CollectiveDraftDtoFromJson(json);

  final String? homeLossReport;
  final String? thirdPartyGuardReport;

  Map<String, dynamic> toJson() => _$CollectiveDraftDtoToJson(this);
}

@JsonSerializable()
class SeparationDraftDto {
  const SeparationDraftDto({
    this.adultInPrison = false,
    this.adolescentInInternment = false,
  });

  factory SeparationDraftDto.fromJson(Map<String, dynamic> json) =>
      _$SeparationDraftDtoFromJson(json);

  final bool adultInPrison;
  final bool adolescentInInternment;

  Map<String, dynamic> toJson() => _$SeparationDraftDtoToJson(this);
}
