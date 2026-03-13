import 'package:shared/src/domain/models/patient.dart';
import 'package:test/test.dart';

void main() {
  group('Patient Domain Models', () {
    test('PersonalData copyWith updates and clears nullable fields', () {
      final data = PersonalData(
        firstName: 'João',
        lastName: 'Silva',
        motherName: 'Maria Silva',
        nationality: 'Brasileiro',
        sex: 'M',
        birthDate: DateTime(1990, 1, 1),
        socialName: 'Joãozinho',
      );

      // Atualiza campos não nulos
      final updated = data.copyWith(firstName: 'José');
      expect(updated.firstName, 'José');
      expect(updated.socialName, 'Joãozinho');

      // Limpa um campo anulável explicitamente
      final cleared = data.copyWith(socialName: () => null);
      expect(cleared.socialName, isNull);
      expect(cleared.firstName, 'João'); // preservado

      // Atualiza um campo anulável
      final setNullable = data.copyWith(phone: () => '11999999999');
      expect(setNullable.phone, '11999999999');
    });

    test('Patient uses Equatable correctly for deep equality', () {
      final personalData = PersonalData(
        firstName: 'João',
        lastName: 'Silva',
        motherName: 'Maria',
        nationality: 'BR',
        sex: 'M',
        birthDate: DateTime(1990),
      );

      final civilDocs = CivilDocuments();

      final address = Address(
        isShelter: false,
        residenceLocation: 'Urbana',
        state: 'SP',
        city: 'São Paulo',
      );

      final patient1 = Patient(
        id: '1',
        personId: 'p1',
        personalData: personalData,
        civilDocuments: civilDocs,
        address: address,
        prRelationshipId: 'r1',
      );

      final patient2 = Patient(
        id: '1',
        personId: 'p1',
        personalData: personalData,
        civilDocuments: civilDocs,
        address: address,
        prRelationshipId: 'r1',
      );

      final patient3 = patient1.copyWith(id: '2');

      expect(patient1, equals(patient2));
      expect(patient1, isNot(equals(patient3)));
    });
  });
}
