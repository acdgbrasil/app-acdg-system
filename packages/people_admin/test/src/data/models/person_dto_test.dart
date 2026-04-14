import 'package:flutter_test/flutter_test.dart';
import 'package:people_admin/src/data/models/person_dto.dart';
import 'package:people_admin/src/domain/models/person.dart';

void main() {
  group('PersonDto', () {
    const validJson = {
      'id': '123e4567-e89b-12d3-a456-426614174000',
      'fullName': 'John Doe',
      'cpf': '12345678901',
      'birthDate': '1990-01-01',
      'email': 'john.doe@example.com',
      'zitadelUserId': 'z-12345',
      'active': true,
      'createdAt': '2026-04-14T10:00:00.000Z',
      'updatedAt': '2026-04-14T10:00:00.000Z',
    };

    test('should parse from valid JSON', () {
      // Act
      final dto = PersonDto.fromJson(validJson);

      // Assert
      expect(dto.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(dto.fullName, 'John Doe');
      expect(dto.active, isTrue);
      expect(dto.createdAt, isA<DateTime>());
    });

    test('should map to Domain Model correctly', () {
      // Arrange
      final dto = PersonDto.fromJson(validJson);

      // Act
      final domain = dto.toDomain();

      // Assert
      expect(domain, isA<Person>());
      expect(domain.id, dto.id);
      expect(domain.fullName, dto.fullName);
      expect(domain.cpf, dto.cpf);
      expect(domain.email, dto.email);
      expect(domain.zitadelUserId, dto.zitadelUserId);
      expect(domain.active, dto.active);
      expect(domain.createdAt, dto.createdAt);
      expect(domain.updatedAt, dto.updatedAt);
    });

    test('should handle null optional fields gracefully', () {
      // Arrange
      final incompleteJson = {
        'id': '123',
        'fullName': 'Jane Doe',
        'active': false,
      };

      // Act
      final dto = PersonDto.fromJson(incompleteJson);
      final domain = dto.toDomain();

      // Assert
      expect(domain.id, '123');
      expect(domain.fullName, 'Jane Doe');
      expect(domain.active, isFalse);
      expect(domain.cpf, isNull);
      expect(domain.birthDate, isNull);
      expect(domain.createdAt, isNull);
    });
  });
}
