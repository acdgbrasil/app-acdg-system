import 'package:test/test.dart';
import 'package:shared/shared.dart';

void main() {
  group('MeResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'userId': '550e8400-e29b-41d4-a716-446655440000',
        'email': 'maria.silva@acdg.org.br',
        'fullName': 'Maria Silva',
        'roles': ['social_worker', 'admin'],
      };
      final dto = MeResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional fullName null', () {
      final json = {
        'userId': '550e8400-e29b-41d4-a716-446655440000',
        'email': 'anon@acdg.org.br',
        'fullName': null,
        'roles': ['owner'],
      };
      final dto = MeResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with empty roles list', () {
      final json = {
        'userId': '550e8400-e29b-41d4-a716-446655440000',
        'email': 'noroles@acdg.org.br',
        'fullName': 'No Roles User',
        'roles': <String>[],
      };
      final dto = MeResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
      expect(dto.roles, isEmpty);
    });

    test('should expose roles as List<String>', () {
      final json = {
        'userId': '1',
        'email': 'x@y.com',
        'fullName': 'X Y',
        'roles': ['social_worker'],
      };
      final dto = MeResponse.fromJson(json);
      expect(dto.roles, isA<List<String>>());
      expect(dto.roles.first, equals('social_worker'));
    });
  });
}
