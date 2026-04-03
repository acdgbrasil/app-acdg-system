import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Patient Registration SRP TDD (Mission 009.3)', () {
    final componentsDir = Directory(p.join('lib', 'src', 'ui', 'patient_registration', 'view', 'components'));

    test('FamilyCompositionFormState must NOT contain FamilyMemberEntry or FamilyMemberSnapshot', () {
      final file = File(p.join(componentsDir.path, 'forms', 'reference_person', 'family_composition_form_state.dart'));
      if (!file.existsSync()) return;
      
      final content = file.readAsStringSync();
      expect(content.contains('class FamilyMemberEntry'), isFalse, 
        reason: 'SRP FAILURE: FamilyMemberEntry should be in its own file.');
      expect(content.contains('class FamilyMemberSnapshot'), isFalse, 
        reason: 'SRP FAILURE: FamilyMemberSnapshot should be in its own file.');
    });

    test('FamilyMemberModal should receive entry via constructor only, not construct it', () {
      final file = File(p.join(componentsDir.path, 'forms', 'reference_person', 'family_member_modal.dart'));
      if (!file.existsSync()) return;
      
      final content = file.readAsStringSync();
      expect(content.contains('widget.entry.name.text = '), isFalse, 
        reason: 'SRP FAILURE: Modal is manually binding initial data to entry. The ViewModel or FormState should provide a pre-bound entry.');
    });
  });
}
