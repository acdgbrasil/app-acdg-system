import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Patient Registration Components Style & Architecture TDD', () {
    final componentsDir = Directory(p.join('lib', 'src', 'ui', 'patient_registration', 'view', 'components'));

    test('FamilyMemberModal should not contain ScaffoldMessenger (View Logic Leak)', () {
      final file = File(p.join(componentsDir.path, 'forms', 'reference_person', 'family_member_modal.dart'));
      if (!file.existsSync()) return;
      
      final content = file.readAsStringSync();
      expect(content.contains('ScaffoldMessenger'), isFalse, 
        reason: 'ScaffoldMessenger found in FamilyMemberModal. View should not handle business validation messages directly.');
    });

    test('FamilyMemberModal should not manage FamilyMemberEntry locally', () {
      final file = File(p.join(componentsDir.path, 'forms', 'reference_person', 'family_member_modal.dart'));
      if (!file.existsSync()) return;
      
      final content = file.readAsStringSync();
      expect(content.contains('_entry = FamilyMemberEntry()'), isFalse, 
        reason: 'View is managing its own FormState. Inject it or move to ViewModel.');
    });

    test('RegistrationErrorModal should not contain hardcoded strings', () {
      final file = File(p.join(componentsDir.path, 'registration_error_modal.dart'));
      if (!file.existsSync()) return;
      
      final content = file.readAsStringSync();
      expect(content.contains("'Sem conexão'"), isFalse, reason: 'Hardcoded string found.');
      expect(content.contains("'Erro no servidor'"), isFalse, reason: 'Hardcoded string found.');
    });

    test('Registration components should not use hardcoded Colors', () {
      final files = componentsDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
      
      for (final file in files) {
        final content = file.readAsStringSync();
        expect(content.contains(RegExp(r'Color\(0x[0-9a-fA-F]+\)')), isFalse, 
          reason: 'Hardcoded Color found in ${file.path}. Use AppColors from design_system.');
      }
    });

    test('Registration components should not build custom radio/checkbox without Design System', () {
      final file = File(p.join(componentsDir.path, 'forms', 'reference_person', 'family_member_modal.dart'));
      if (!file.existsSync()) return;

      final content = file.readAsStringSync();
      // Should not have containers acting as manual radios
      expect(content.contains('BoxShape.circle'), isFalse, 
        reason: 'Manual Radio Button detected. Use AcdgRadioButton from design_system.');
    });
  });
}
