import 'dart:convert';

import 'package:test/test.dart';
import 'package:shared/shared.dart';

void main() {
  group('TeamMemberDetailResponse', () {
    test('should round-trip with all fields and roles populated', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'personId': '660e8400-e29b-41d4-a716-446655440001',
        'fullName': 'Maria Silva',
        'email': 'maria.silva@acdg.org.br',
        'phone': '11999990000',
        'active': true,
        'roles': [
          {
            'id': '770e8400-e29b-41d4-a716-446655440002',
            'personId': '660e8400-e29b-41d4-a716-446655440001',
            'system': 'social-care',
            'role': 'social_worker',
            'active': true,
            'fullName': 'Maria Silva',
            'assignedAt': '2024-01-15T08:00:00Z',
          },
          {
            'id': '880e8400-e29b-41d4-a716-446655440003',
            'personId': '660e8400-e29b-41d4-a716-446655440001',
            'system': 'social-care',
            'role': 'admin',
            'active': false,
            'fullName': 'Maria Silva',
            'assignedAt': '2024-02-20T10:00:00Z',
          },
        ],
        'createdAt': '2024-01-15T08:00:00Z',
      };
      final dto = TeamMemberDetailResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto)) as Map<String, dynamic>;
      expect(result, equals(json));
    });

    test('should round-trip with empty roles list', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'personId': '660e8400-e29b-41d4-a716-446655440001',
        'fullName': 'Joao Santos',
        'email': null,
        'phone': null,
        'active': false,
        'roles': <Map<String, dynamic>>[],
        'createdAt': '2024-01-15T08:00:00Z',
      };
      final dto = TeamMemberDetailResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto)) as Map<String, dynamic>;
      expect(result, equals(json));
      expect(dto.roles, isEmpty);
    });

    test('should expose roles as List<PersonRoleResponse>', () {
      final json = {
        'id': '1',
        'personId': '2',
        'fullName': 'X Y',
        'email': null,
        'phone': null,
        'active': true,
        'roles': [
          {
            'id': '3',
            'personId': '2',
            'system': 'social-care',
            'role': 'owner',
            'active': true,
            'fullName': null,
            'assignedAt': null,
          },
        ],
        'createdAt': '2024-01-15T08:00:00Z',
      };
      final dto = TeamMemberDetailResponse.fromJson(json);
      expect(dto.roles, isA<List<PersonRoleResponse>>());
      expect(dto.roles, hasLength(1));
      expect(dto.roles.first.role, equals('owner'));
    });

    test('should preserve ISO-8601 createdAt verbatim', () {
      final json = {
        'id': '1',
        'personId': '2',
        'fullName': 'X Y',
        'email': null,
        'phone': null,
        'active': true,
        'roles': <Map<String, dynamic>>[],
        'createdAt': '2024-01-15T08:00:00.123Z',
      };
      final dto = TeamMemberDetailResponse.fromJson(json);
      expect(dto.createdAt, equals('2024-01-15T08:00:00.123Z'));
    });
  });
}
