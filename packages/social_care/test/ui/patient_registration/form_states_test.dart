import 'package:flutter_test/flutter_test.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/family_composition_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/specificities_form_state.dart';
import 'package:social_care/src/ui/patient_registration/view/components/forms/reference_person/intake_info_form_state.dart';

void main() {
  // ── FamilyCompositionFormState ────────────────────────────────

  group('FamilyCompositionFormState', () {
    late FamilyCompositionFormState state;

    setUp(() => state = FamilyCompositionFormState());
    tearDown(() => state.dispose());

    test('starts with empty members list', () {
      expect(state.members.value, isEmpty);
    });

    test('isValidForNextStep is always true (optional step)', () {
      expect(state.isValidForNextStep, isTrue);
    });

    test('addMember appends to the list', () {
      final member = _createSnapshot(name: 'João');
      state.addMember(member);
      expect(state.members.value.length, 1);
      expect(state.members.value.first.name, 'João');
    });

    test('updateMember replaces at index', () {
      state.addMember(_createSnapshot(name: 'João'));
      state.addMember(_createSnapshot(name: 'Maria'));

      state.updateMember(0, _createSnapshot(name: 'Pedro'));

      expect(state.members.value[0].name, 'Pedro');
      expect(state.members.value[1].name, 'Maria');
    });

    test('removeMember removes at index', () {
      state.addMember(_createSnapshot(name: 'João'));
      state.addMember(_createSnapshot(name: 'Maria'));

      state.removeMember(0);

      expect(state.members.value.length, 1);
      expect(state.members.value.first.name, 'Maria');
    });

    test('removeMember ignores invalid index', () {
      state.addMember(_createSnapshot(name: 'João'));

      state.removeMember(-1);
      state.removeMember(5);

      expect(state.members.value.length, 1);
    });

    test('hasPrimaryCaregiver returns true when a caregiver exists', () {
      state.addMember(_createSnapshot(name: 'João', isCaregiver: false));
      expect(state.hasPrimaryCaregiver, isFalse);

      state.addMember(_createSnapshot(name: 'Maria', isCaregiver: true));
      expect(state.hasPrimaryCaregiver, isTrue);
    });
  });

  // ── FamilyMemberEntry ────────────────────────────────────────

  group('FamilyMemberEntry', () {
    late FamilyMemberEntry entry;

    setUp(() => entry = FamilyMemberEntry());
    tearDown(() => entry.dispose());

    test('empty entry is invalid', () {
      expect(entry.isValid, isFalse);
      expect(entry.nameError, isNotNull);
      expect(entry.birthDateError, isNotNull);
      expect(entry.sexError, isNotNull);
      expect(entry.relationshipError, isNotNull);
      expect(entry.hasDisabilityError, isNotNull);
    });

    test('complete entry is valid', () {
      entry.name.text = 'Maria da Silva';
      entry.birthDate.text = '15071990';
      entry.sex.value = 'feminino';
      entry.relationship.value = '03';
      entry.hasDisability.value = false;

      expect(entry.isValid, isTrue);
      expect(entry.validationErrors, isEmpty);
    });

    test('name with less than 3 chars shows min error', () {
      entry.name.text = 'AB';
      expect(entry.nameError, contains('3'));
    });

    test('birthDate parses correctly', () {
      entry.birthDate.text = '15071990';
      expect(entry.dateParsed, DateTime(1990, 7, 15));
    });

    test('invalid birthDate returns null dateParsed', () {
      entry.birthDate.text = '32131990';
      expect(entry.dateParsed, isNull);
      expect(entry.birthDateError, isNotNull);
    });
  });

  // ── FamilyMemberSnapshot ─────────────────────────────────────

  group('FamilyMemberSnapshot', () {
    test('age calculation works', () {
      final now = DateTime.now();
      final snapshot = FamilyMemberSnapshot(
        name: 'Test',
        birthDate: DateTime(now.year - 25, now.month, now.day),
        sex: 'masculino',
        relationshipCode: '03',
        hasDisability: false,
        isResiding: true,
        isCaregiver: false,
        requiredDocuments: const {},
      );

      expect(snapshot.age, 25);
    });
  });

  // ── SpecificitiesFormState ───────────────────────────────────

  group('SpecificitiesFormState', () {
    late SpecificitiesFormState state;

    setUp(() => state = SpecificitiesFormState());
    tearDown(() => state.dispose());

    test('starts with no selection', () {
      expect(state.selectedIdentity.value, isNull);
      expect(state.isDescriptionEnabled, isFalse);
    });

    test('isValidForNextStep is always true (optional step)', () {
      expect(state.isValidForNextStep, isTrue);
    });

    test('selecting identity that requires description enables text field', () {
      state.selectIdentity('indigena_aldeia');
      expect(state.isDescriptionEnabled, isTrue);
    });

    test('selecting identity without description disables text field', () {
      state.selectIdentity('cigana');
      expect(state.isDescriptionEnabled, isFalse);
    });

    test('switching from description-required to non clears text', () {
      state.selectIdentity('indigena_aldeia');
      state.identityDescription.text = 'Guarani';

      state.selectIdentity('quilombola');

      expect(state.identityDescription.text, isEmpty);
      expect(state.isDescriptionEnabled, isFalse);
    });

    test('deselecting clears description', () {
      state.selectIdentity('outras');
      state.identityDescription.text = 'Descrição teste';

      state.selectIdentity(null);

      expect(state.identityDescription.text, isEmpty);
    });
  });

  // ── IntakeInfoFormState ──────────────────────────────────────

  group('IntakeInfoFormState', () {
    late IntakeInfoFormState state;

    setUp(() => state = IntakeInfoFormState());
    tearDown(() => state.dispose());

    test('starts with no selection and empty fields', () {
      expect(state.ingressType.value, isNull);
      expect(state.serviceReason.text, isEmpty);
      expect(state.selectedPrograms.value, isEmpty);
    });

    test('is invalid without ingress type and service reason', () {
      expect(state.isValidForNextStep, isFalse);
      expect(state.ingressTypeError, isNotNull);
      expect(state.serviceReasonError, isNotNull);
    });

    test('is valid with ingress type and service reason', () {
      state.ingressType.value = 'espontaneo';
      state.serviceReason.text = 'Motivo do atendimento';

      expect(state.isValidForNextStep, isTrue);
      expect(state.validationErrors, isEmpty);
    });

    test('toggleProgram adds and removes programs', () {
      state.toggleProgram('Bolsa Família');
      expect(state.selectedPrograms.value, contains('Bolsa Família'));

      state.toggleProgram('Bolsa Família');
      expect(state.selectedPrograms.value, isNot(contains('Bolsa Família')));
    });

    test('multiple programs can be selected', () {
      state.toggleProgram('Bolsa Família');
      state.toggleProgram('BPC');
      state.toggleProgram('PETI');

      expect(state.selectedPrograms.value.length, 3);
    });

    test('validationErrors lists missing fields', () {
      final errors = state.validationErrors;
      expect(errors.length, 2);
    });
  });
}

// ── Test helper ──

FamilyMemberSnapshot _createSnapshot({
  required String name,
  bool isCaregiver = false,
}) {
  return FamilyMemberSnapshot(
    name: name,
    birthDate: DateTime(1990, 1, 1),
    sex: 'masculino',
    relationshipCode: '03',
    hasDisability: false,
    isResiding: true,
    isCaregiver: isCaregiver,
    requiredDocuments: const {},
  );
}
