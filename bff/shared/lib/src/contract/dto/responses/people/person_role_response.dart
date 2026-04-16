import 'package:json_annotation/json_annotation.dart';

part 'person_role_response.g.dart';

@JsonSerializable()
class PersonRoleResponse {
  const PersonRoleResponse({
    required this.id,
    required this.personId,
    required this.system,
    required this.role,
    required this.active,
    this.fullName,
    this.assignedAt,
  });

  factory PersonRoleResponse.fromJson(Map<String, dynamic> json) =>
      _$PersonRoleResponseFromJson(json);

  final String id;
  final String personId;
  final String system;
  final String role;
  final bool active;
  final String? fullName;
  final String? assignedAt;

  Map<String, dynamic> toJson() => _$PersonRoleResponseToJson(this);
}
