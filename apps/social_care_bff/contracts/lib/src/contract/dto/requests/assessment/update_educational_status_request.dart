import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_educational_status_request.g.dart';

@JsonSerializable()
class UpdateEducationalStatusRequest with Equatable {
  const UpdateEducationalStatusRequest({
    this.memberProfiles = const [],
    this.programOccurrences = const [],
  });

  factory UpdateEducationalStatusRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateEducationalStatusRequestFromJson(json);

  final List<ProfileDraftDto> memberProfiles;
  final List<OccurrenceDraftDto> programOccurrences;

  Map<String, dynamic> toJson() => _$UpdateEducationalStatusRequestToJson(this);

  @override
  List<Object?> get props => [memberProfiles, programOccurrences];
}

@JsonSerializable()
class ProfileDraftDto with Equatable {
  const ProfileDraftDto({
    required this.memberId,
    required this.canReadWrite,
    required this.attendsSchool,
    required this.educationLevelId,
  });

  factory ProfileDraftDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileDraftDtoFromJson(json);

  final String memberId;
  final bool canReadWrite;
  final bool attendsSchool;
  final String educationLevelId;

  Map<String, dynamic> toJson() => _$ProfileDraftDtoToJson(this);

  @override
  List<Object?> get props => [
    memberId,
    canReadWrite,
    attendsSchool,
    educationLevelId,
  ];
}

@JsonSerializable()
class OccurrenceDraftDto with Equatable {
  const OccurrenceDraftDto({
    required this.memberId,
    required this.date,
    required this.effectId,
    required this.isSuspensionRequested,
  });

  factory OccurrenceDraftDto.fromJson(Map<String, dynamic> json) =>
      _$OccurrenceDraftDtoFromJson(json);

  final String memberId;
  final String date;
  final String effectId;
  final bool isSuspensionRequested;

  Map<String, dynamic> toJson() => _$OccurrenceDraftDtoToJson(this);

  @override
  List<Object?> get props => [
    memberId,
    date,
    effectId,
    isSuspensionRequested,
  ];
}
