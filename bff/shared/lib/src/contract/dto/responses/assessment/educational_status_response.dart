import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'educational_status_response.g.dart';

@JsonSerializable()
class EducationalStatusResponse with Equatable {
  const EducationalStatusResponse({
    this.memberProfiles = const [],
    this.programOccurrences = const [],
  });

  factory EducationalStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$EducationalStatusResponseFromJson(json);

  final List<EducationalProfileResponse> memberProfiles;
  final List<ProgramOccurrenceResponse> programOccurrences;

  Map<String, dynamic> toJson() => _$EducationalStatusResponseToJson(this);

  @override
  List<Object?> get props => [memberProfiles, programOccurrences];
}

@JsonSerializable()
class EducationalProfileResponse with Equatable {
  const EducationalProfileResponse({
    required this.memberId,
    required this.canReadWrite,
    required this.attendsSchool,
    required this.educationLevelId,
  });

  factory EducationalProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$EducationalProfileResponseFromJson(json);

  final String memberId;
  final bool canReadWrite;
  final bool attendsSchool;
  final String educationLevelId;

  Map<String, dynamic> toJson() => _$EducationalProfileResponseToJson(this);

  @override
  List<Object?> get props => [
    memberId,
    canReadWrite,
    attendsSchool,
    educationLevelId,
  ];
}

@JsonSerializable()
class ProgramOccurrenceResponse with Equatable {
  const ProgramOccurrenceResponse({
    required this.memberId,
    required this.date,
    required this.effectId,
    required this.isSuspensionRequested,
  });

  factory ProgramOccurrenceResponse.fromJson(Map<String, dynamic> json) =>
      _$ProgramOccurrenceResponseFromJson(json);

  final String memberId;
  final String date;
  final String effectId;
  final bool isSuspensionRequested;

  Map<String, dynamic> toJson() => _$ProgramOccurrenceResponseToJson(this);

  @override
  List<Object?> get props => [
    memberId,
    date,
    effectId,
    isSuspensionRequested,
  ];
}
