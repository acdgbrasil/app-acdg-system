import 'package:flutter_test/flutter_test.dart';
import 'package:social_care/src/ui/family_composition/models/family_member_model.dart';

void main() {
  group('FamilyMemberModel', () {
    FamilyMemberModel createModel({
      DateTime? birthDate,
      bool isReferencePerson = false,
      bool isPrimaryCaregiver = false,
      Set<String> requiredDocuments = const {},
    }) {
      return FamilyMemberModel(
        personId: '550e8400-e29b-41d4-a716-446655440000',
        relationshipLabel: '03 - Filho(a)',
        relationshipCode: '03',
        birthDate: birthDate ?? DateTime(2000, 6, 15),
        sex: 'Masculino',
        isReferencePerson: isReferencePerson,
        isPrimaryCaregiver: isPrimaryCaregiver,
        residesWithPatient: true,
        hasDisability: false,
        requiredDocuments: requiredDocuments,
      );
    }

    test('displayName shows truncated personId', () {
      final model = createModel();
      expect(model.displayName, '550e8400…');
    });

    test('age calculation is precise when birthday has not passed', () {
      final now = DateTime.now();
      final birthDate = DateTime(now.year - 30, now.month, now.day + 1);
      final model = createModel(birthDate: birthDate);
      expect(model.age, 29);
    });

    test('age calculation is precise when birthday has passed', () {
      final now = DateTime.now();
      final birthDate = DateTime(now.year - 30, now.month, now.day - 1);
      final model = createModel(birthDate: birthDate);
      expect(model.age, 30);
    });

    test('age calculation is precise on birthday', () {
      final now = DateTime.now();
      final birthDate = DateTime(now.year - 25, now.month, now.day);
      final model = createModel(birthDate: birthDate);
      expect(model.age, 25);
    });

    test('copyWith preserves unchanged fields', () {
      final original = createModel(
        isPrimaryCaregiver: true,
        requiredDocuments: {'RG', 'CPF'},
      );

      final modified = original.copyWith(isPrimaryCaregiver: false);

      expect(modified.isPrimaryCaregiver, false);
      expect(modified.personId, original.personId);
      expect(modified.requiredDocuments, {'RG', 'CPF'});
      expect(modified.sex, 'Masculino');
    });

    test('copyWith updates requiredDocuments', () {
      final original = createModel(requiredDocuments: {'RG'});
      final modified = original.copyWith(requiredDocuments: {'RG', 'CPF', 'CN'});

      expect(modified.requiredDocuments, {'RG', 'CPF', 'CN'});
      expect(original.requiredDocuments, {'RG'});
    });
  });
}
