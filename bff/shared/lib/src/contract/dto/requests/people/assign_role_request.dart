import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'assign_role_request.g.dart';

@JsonSerializable()
class AssignRoleRequest with Equatable {
  const AssignRoleRequest({required this.system, required this.role});

  factory AssignRoleRequest.fromJson(Map<String, dynamic> json) =>
      _$AssignRoleRequestFromJson(json);

  final String system;
  final String role;

  Map<String, dynamic> toJson() => _$AssignRoleRequestToJson(this);

  @override
  List<Object?> get props => [system, role];
}
