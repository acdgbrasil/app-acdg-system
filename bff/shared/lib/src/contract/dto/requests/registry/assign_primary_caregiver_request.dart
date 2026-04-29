import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'assign_primary_caregiver_request.g.dart';

@JsonSerializable()
class AssignPrimaryCaregiverRequest with Equatable {
  const AssignPrimaryCaregiverRequest({required this.memberPersonId});

  factory AssignPrimaryCaregiverRequest.fromJson(Map<String, dynamic> json) =>
      _$AssignPrimaryCaregiverRequestFromJson(json);

  final String memberPersonId;

  Map<String, dynamic> toJson() => _$AssignPrimaryCaregiverRequestToJson(this);

  @override
  List<Object?> get props => [memberPersonId];
}
