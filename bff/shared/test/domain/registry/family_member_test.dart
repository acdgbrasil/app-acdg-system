import 'package:core/core.dart';
import 'package:shared/src/domain/kernel/ids.dart';
import 'package:shared/src/domain/kernel/time_stamp.dart';
import 'package:shared/src/domain/registry/family_member.dart';
import 'package:shared/src/domain/registry/registry_vos.dart';
import 'package:test/test.dart';

void main() {
  group('FamilyMember - Validações', () {
    final personId = PersonId.create('550e8400-e29b-41d4-a716-446655440000').valueOrNull!;
    final relId = LookupId.create('550e8400-e29b-41d4-a716-446655440001').valueOrNull!;
    final birthDate = TimeStamp.fromIso('2010-01-01T00:00:00.000Z').valueOrNull!;

    test('Deve criar com sucesso e ordenar documentos', () {
      final result = FamilyMember.create(
        personId: personId,
        relationshipId: relId,
        residesWithPatient: true,
        birthDate: birthDate,
        requiredDocuments: [RequiredDocument.cpf, RequiredDocument.rg, RequiredDocument.cpf],
      );

      expect(result.isSuccess, isTrue);
      final fm = result.valueOrNull!;
      expect(fm.requiredDocuments.length, 2); // deduplicado
      expect(fm.requiredDocuments[0], RequiredDocument.cpf); // CPF vem antes de RG na ordenação alfabética do enum.value
    });

    test('Igualdade baseada apenas no personId', () {
      final fm1 = FamilyMember.create(
        personId: personId,
        relationshipId: relId,
        residesWithPatient: true,
        birthDate: birthDate,
      ).valueOrNull!;

      final fm2 = fm1.copyWith(residesWithPatient: false);

      expect(fm1, equals(fm2));
    });
  });
}
