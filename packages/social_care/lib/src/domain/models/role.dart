import 'package:core/core.dart';

/// A role assignment that grants a [Person] access to a subsystem.
///
/// [type] is a string identifier (e.g. `social_worker`, `owner`, `admin`);
/// the exact vocabulary is defined by the BFF.
class Role with Equatable {
  const Role({
    required this.roleId,
    required this.personId,
    required this.system,
    required this.type,
    required this.active,
    this.fullName,
    this.assignedAt,
  });

  final String roleId;
  final String personId;
  final String system;
  final String type;
  final bool active;
  final String? fullName;
  final String? assignedAt;

  Role copyWith({
    String? roleId,
    String? personId,
    String? system,
    String? type,
    bool? active,
    String? fullName,
    String? assignedAt,
  }) {
    return Role(
      roleId: roleId ?? this.roleId,
      personId: personId ?? this.personId,
      system: system ?? this.system,
      type: type ?? this.type,
      active: active ?? this.active,
      fullName: fullName ?? this.fullName,
      assignedAt: assignedAt ?? this.assignedAt,
    );
  }

  @override
  List<Object?> get props => [
    roleId,
    personId,
    system,
    type,
    active,
    fullName,
    assignedAt,
  ];
}
