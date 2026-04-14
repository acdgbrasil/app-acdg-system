import 'package:equatable/equatable.dart';
import '../../domain/models/system_role.dart';

final class SystemRoleDto with EquatableMixin {
  const SystemRoleDto({
    required this.id,
    required this.personId,
    required this.system,
    required this.role,
    required this.active,
    this.assignedAt,
  });

  final String id;
  final String personId;
  final String system;
  final String role;
  final bool active;
  final DateTime? assignedAt;

  @override
  List<Object?> get props => [id, personId, system, role, active, assignedAt];

  factory SystemRoleDto.fromJson(Map<String, dynamic> json) {
    return SystemRoleDto(
      id: json['id'] as String? ?? '',
      personId: json['personId'] as String? ?? '',
      system: json['system'] as String? ?? '',
      role: json['role'] as String? ?? '',
      active: json['active'] as bool? ?? false,
      assignedAt:
          json['assignedAt'] != null
              ? DateTime.tryParse(json['assignedAt'] as String)
              : null,
    );
  }

  SystemRole toDomain() {
    return SystemRole(
      id: id,
      personId: personId,
      system: system,
      role: role,
      active: active,
      assignedAt: assignedAt,
    );
  }
}
