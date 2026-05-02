import 'package:test/test.dart';
import 'package:shared/shared.dart';

void main() {
  group('TeamMemberResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'personId': '660e8400-e29b-41d4-a716-446655440001',
        'fullName': 'Maria Silva',
        'email': 'maria.silva@acdg.org.br',
        'phone': '11999990000',
        'active': true,
        'primaryRole': 'social_worker',
      };
      final dto = TeamMemberResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional fields null', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'personId': '660e8400-e29b-41d4-a716-446655440001',
        'fullName': 'Joao Santos',
        'email': null,
        'phone': null,
        'active': false,
        'primaryRole': null,
      };
      final dto = TeamMemberResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should expose active as bool flag', () {
      final json = {
        'id': '1',
        'personId': '2',
        'fullName': 'X Y',
        'email': null,
        'phone': null,
        'active': true,
        'primaryRole': null,
      };
      final dto = TeamMemberResponse.fromJson(json);
      expect(dto.active, isTrue);
    });

    test('should accept admin as primaryRole', () {
      final json = {
        'id': '1',
        'personId': '2',
        'fullName': 'Admin User',
        'email': 'admin@acdg.org.br',
        'phone': null,
        'active': true,
        'primaryRole': 'admin',
      };
      final dto = TeamMemberResponse.fromJson(json);
      expect(dto.primaryRole, equals('admin'));
    });
  });
}
