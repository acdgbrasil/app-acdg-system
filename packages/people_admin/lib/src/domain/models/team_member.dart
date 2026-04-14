import 'package:equatable/equatable.dart';

final class TeamMember with EquatableMixin {
  const TeamMember({
    required this.personId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.roleId,
    required this.active,
    this.cpf,
    this.birthDate,
  });

  final String personId;
  final String fullName;
  final String? email;
  final String role;
  final String roleId;
  final bool active;
  final String? cpf;
  final String? birthDate;

  @override
  List<Object?> get props => [personId, fullName, email, role, roleId, active];

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final person = json['person'] as Map<String, dynamic>? ?? {};
    final roleData = json['role'] as Map<String, dynamic>? ?? {};
    return TeamMember(
      personId: person['personId'] as String? ?? '',
      fullName: person['fullName'] as String? ?? '',
      email: person['email'] as String?,
      cpf: person['cpf'] as String?,
      birthDate: person['birthDate'] as String?,
      role: roleData['role'] as String? ?? '',
      roleId: roleData['id'] as String? ?? '',
      active: roleData['active'] as bool? ?? true,
    );
  }
}
