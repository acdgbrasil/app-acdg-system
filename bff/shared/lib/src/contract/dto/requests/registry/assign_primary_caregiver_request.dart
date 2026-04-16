import 'package:json_annotation/json_annotation.dart';

part 'assign_primary_caregiver_request.g.dart';

@JsonSerializable()
class AssignPrimaryCaregiverRequest {
  const AssignPrimaryCaregiverRequest({required this.memberPersonId});

  factory AssignPrimaryCaregiverRequest.fromJson(Map<String, dynamic> json) =>
      _$AssignPrimaryCaregiverRequestFromJson(json);

  final String memberPersonId;

  Map<String, dynamic> toJson() => _$AssignPrimaryCaregiverRequestToJson(this);
}
