import 'package:flutter_test/flutter_test.dart';
import 'package:people_admin/src/data/models/system_role_dto.dart';
import 'package:people_admin/src/domain/models/system_role.dart';

void main() {
  group('SystemRoleDto', () {
    const validJson = {
      'id': 'role-123',
      'personId': 'person-123',
      'system': 'social-care',
      'role': 'admin',
      'active': true,
      'assignedAt': '2026-04-14T10:00:00.000Z',
    };

    test('should parse from valid JSON', () {
      final dto = SystemRoleDto.fromJson(validJson);

      expect(dto.id, 'role-123');
      expect(dto.personId, 'person-123');
      expect(dto.system, 'social-care');
      expect(dto.role, 'admin');
      expect(dto.active, isTrue);
      expect(dto.assignedAt, isA<DateTime>());
    });

    test('should map to Domain Model correctly', () {
      final dto = SystemRoleDto.fromJson(validJson);
      final domain = dto.toDomain();

      expect(domain, isA<SystemRole>());
      expect(domain.id, dto.id);
      expect(domain.personId, dto.personId);
      expect(domain.system, dto.system);
      expect(domain.role, dto.role);
      expect(domain.active, dto.active);
      expect(domain.assignedAt, dto.assignedAt);
    });
  });
}
