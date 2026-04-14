import 'package:equatable/equatable.dart';

final class SystemRole with EquatableMixin {
  const SystemRole({
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
}
