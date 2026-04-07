import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Resolves the package root for social_care regardless of CWD.
String _packageRoot() {
  // When run from monorepo root, CWD won't contain pubspec.yaml for social_care.
  final cwd = Directory.current.path;
  if (File(p.join(cwd, 'pubspec.yaml')).existsSync() &&
      File(
        p.join(cwd, 'pubspec.yaml'),
      ).readAsStringSync().contains('name: social_care')) {
    return cwd;
  }
  // Fallback: resolve from this test file's known location.
  return p.normalize(p.join(cwd, 'packages', 'social_care'));
}

void main() {
  group('Home Components Style & Architecture TDD', () {
    final homeDir = Directory(
      p.join(_packageRoot(), 'lib', 'src', 'ui', 'home'),
    );

    test('Home components should not use hardcoded Colors', () {
      final files = homeDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in files) {
        final content = file.readAsStringSync();
        expect(
          content.contains(RegExp(r'Color\(0x[0-9a-fA-F]+\)')),
          isFalse,
          reason:
              'Hardcoded Color found in ${file.path}. Use AppColors from design_system.',
        );
      }
    });

    test('Home page should use Riverpod, not Provider legacy', () {
      final file = File(p.join(homeDir.path, 'view', 'page', 'home_page.dart'));
      if (!file.existsSync()) return;

      final content = file.readAsStringSync();
      expect(
        content.contains('context.read<HomeViewModel>()'),
        isFalse,
        reason:
            'Legacy Provider usage detected. Use ConsumerWidget and ref.watch/read.',
      );
    });
  });
}
