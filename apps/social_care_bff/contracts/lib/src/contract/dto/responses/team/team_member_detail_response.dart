import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

import '../people/person_role_response.dart';

part 'team_member_detail_response.g.dart';

@JsonSerializable(explicitToJson: true)
class TeamMemberDetailResponse with Equatable {
  const TeamMemberDetailResponse({
    required this.id,
    required this.personId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.active,
    required this.roles,
    required this.createdAt,
  });

  factory TeamMemberDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$TeamMemberDetailResponseFromJson(json);

  final String id;
  final String personId;
  final String fullName;
  final String? email;
  final String? phone;
  final bool active;
  final List<PersonRoleResponse> roles;
  final String createdAt;

  Map<String, dynamic> toJson() => _$TeamMemberDetailResponseToJson(this);

  @override
  List<Object?> get props => [
    id,
    personId,
    fullName,
    email,
    phone,
    active,
    roles,
    createdAt,
  ];
}
