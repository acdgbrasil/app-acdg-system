import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'team_member_response.g.dart';

@JsonSerializable()
class TeamMemberResponse with Equatable {
  const TeamMemberResponse({
    required this.id,
    required this.personId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.active,
    required this.primaryRole,
  });

  factory TeamMemberResponse.fromJson(Map<String, dynamic> json) =>
      _$TeamMemberResponseFromJson(json);

  final String id;
  final String personId;
  final String fullName;
  final String? email;
  final String? phone;
  final bool active;
  final String? primaryRole;

  Map<String, dynamic> toJson() => _$TeamMemberResponseToJson(this);

  @override
  List<Object?> get props => [
    id,
    personId,
    fullName,
    email,
    phone,
    active,
    primaryRole,
  ];
}
