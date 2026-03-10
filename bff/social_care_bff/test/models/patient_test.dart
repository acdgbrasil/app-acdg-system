import 'package:social_care_bff/social_care_bff.dart';
import 'package:test/test.dart';

void main() {
  group('Patient', () {
    test('equality by patientId', () {
      const p1 = Patient(
        patientId: 'p-1',
        personId: 'person-1',
        version: 1,
        familyMembers: [],
        diagnoses: [],
        appointments: [],
        referrals: [],
        violationReports: [],
        computedAnalytics: ComputedAnalytics(),
      );
      const p2 = Patient(
        patientId: 'p-1',
        personId: 'person-different',
        version: 5,
        familyMembers: [],
        diagnoses: [],
        appointments: [],
        referrals: [],
        violationReports: [],
        computedAnalytics: ComputedAnalytics(),
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });

    test('toString includes id and version', () {
      const p = Patient(
        patientId: 'abc-123',
        personId: 'person-1',
        version: 3,
        familyMembers: [],
        diagnoses: [],
        appointments: [],
        referrals: [],
        violationReports: [],
        computedAnalytics: ComputedAnalytics(),
      );

      expect(p.toString(), 'Patient(id: abc-123, v3)');
    });
  });

  group('PersonalData', () {
    test('fullName concatenates first and last name', () {
      const data = PersonalData(firstName: 'Maria', lastName: 'Silva');
      expect(data.fullName, 'Maria Silva');
    });

    test('fullName handles null parts', () {
      const data = PersonalData(firstName: 'João');
      expect(data.fullName, 'João');
    });

    test('fullName is empty when no names', () {
      const data = PersonalData();
      expect(data.fullName, '');
    });
  });

  group('LookupItem', () {
    test('equality by all fields', () {
      const a = LookupItem(id: '1', codigo: 'PAI', descricao: 'Pai');
      const b = LookupItem(id: '1', codigo: 'PAI', descricao: 'Pai');
      expect(a, equals(b));
    });

    test('inequality when different', () {
      const a = LookupItem(id: '1', codigo: 'PAI', descricao: 'Pai');
      const b = LookupItem(id: '2', codigo: 'MAE', descricao: 'Mãe');
      expect(a, isNot(equals(b)));
    });
  });

  group('FamilyMember', () {
    test('equality by personId', () {
      const fm1 = FamilyMember(
        personId: 'fm-1',
        relationshipId: 'rel-1',
        isPrimaryCaregiver: false,
        residesWithPatient: true,
        hasDisability: false,
        requiredDocuments: [],
      );
      const fm2 = FamilyMember(
        personId: 'fm-1',
        relationshipId: 'rel-2',
        isPrimaryCaregiver: true,
        residesWithPatient: false,
        hasDisability: true,
        requiredDocuments: ['doc'],
      );

      expect(fm1, equals(fm2));
    });
  });

  group('Appointment', () {
    test('equality by id', () {
      const a1 = Appointment(id: 'app-1', professionalId: 'prof-1');
      const a2 = Appointment(
        id: 'app-1',
        professionalId: 'prof-2',
        summary: 'test',
      );

      expect(a1, equals(a2));
    });
  });
}
