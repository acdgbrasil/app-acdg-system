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
  group('Riverpod Legacy Purge TDD (Mission 010)', () {
    test('No files should import flutter_riverpod/legacy.dart', () {
      final libDir = Directory(p.join(_packageRoot(), 'lib'));
      final files = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in files) {
        final content = file.readAsStringSync();
        expect(
          content.contains('flutter_riverpod/legacy.dart'),
          isFalse,
          reason:
              'CRITICAL FAILURE: Legacy Riverpod import found in ${file.path}. Use standard Provider + ref.onDispose instead of ChangeNotifierProvider.',
        );
      }
    });

    test('No files should use ChangeNotifierProvider', () {
      final libDir = Directory(p.join(_packageRoot(), 'lib'));
      final files = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in files) {
        final content = file.readAsStringSync();
        expect(
          content.contains('ChangeNotifierProvider'),
          isFalse,
          reason:
              'CRITICAL FAILURE: ChangeNotifierProvider found in ${file.path}. The project MUST migrate to Provider + ref.onDispose + ListenableBuilder, or Riverpod Notifier.',
        );
      }
    });
  });
}
