import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Resolves the package root for social_care regardless of CWD.
String _packageRoot() {
  final cwd = Directory.current.path;
  if (File(p.join(cwd, 'pubspec.yaml')).existsSync() &&
      File(
        p.join(cwd, 'pubspec.yaml'),
      ).readAsStringSync().contains('name: social_care')) {
    return cwd;
  }
  return p.normalize(p.join(cwd, 'packages', 'social_care'));
}

void main() {
  group('Patient Registration Arch TDD (Mission 009.1)', () {
    final componentsDir = Directory(
      p.join(
        _packageRoot(),
        'lib',
        'src',
        'ui',
        'patient_registration',
        'view',
        'components',
      ),
    );

    test(
      'FamilyMemberModal should NOT contain View Logic Leaks (ScaffoldMessenger, Navigator)',
      () {
        final file = File(
          p.join(
            componentsDir.path,
            'forms',
            'reference_person',
            'family_member_modal.dart',
          ),
        );
        if (!file.existsSync()) return;

        final content = file.readAsStringSync();
        expect(
          content.contains('ScaffoldMessenger.of'),
          isFalse,
          reason:
              'CRITICAL FAILURE: ScaffoldMessenger found in FamilyMemberModal. The View should not handle business validation messages directly.',
        );
      },
    );

    test('FamilyMemberModal should NOT manage Local State directly', () {
      final file = File(
        p.join(
          componentsDir.path,
          'forms',
          'reference_person',
          'family_member_modal.dart',
        ),
      );
      if (!file.existsSync()) return;

      final content = file.readAsStringSync();
      expect(
        content.contains('_entry = FamilyMemberEntry()'),
        isFalse,
        reason:
            'CRITICAL FAILURE: View is managing its own FormState. Inject it or move to the parent ViewModel.',
      );
    });

    test('RegistrationErrorModal should NOT contain Hardcoded Strings', () {
      final file = File(
        p.join(componentsDir.path, 'registration_error_modal.dart'),
      );
      if (!file.existsSync()) return;

      final content = file.readAsStringSync();
      // Ensure we use a Constants/Localization file
      expect(
        content.contains(RegExp(r"'Sem conexão'|'Erro no servidor'")),
        isFalse,
        reason:
            'CRITICAL FAILURE: Hardcoded Portuguese strings found in the UI. Move to constants/l10n file.',
      );
    });

    test('Registration components should NOT use Hardcoded Colors', () {
      final files = componentsDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in files) {
        final content = file.readAsStringSync();
        expect(
          content.contains(RegExp(r'Color\(0x[0-9a-fA-F]+\)')),
          isFalse,
          reason:
              'CRITICAL FAILURE: Hardcoded Color found in ${file.path}. Use AppColors tokens exclusively.',
        );
      }
    });

    test('Registration components MUST use Design System for Inputs', () {
      final file = File(
        p.join(
          componentsDir.path,
          'forms',
          'reference_person',
          'family_member_modal.dart',
        ),
      );
      if (!file.existsSync()) return;

      final content = file.readAsStringSync();
      expect(
        content.contains('BoxShape.circle'),
        isFalse,
        reason:
            'CRITICAL FAILURE: Manual Radio Button drawing detected. Use AcdgRadioButton from the design_system.',
      );
    });
  });
}
