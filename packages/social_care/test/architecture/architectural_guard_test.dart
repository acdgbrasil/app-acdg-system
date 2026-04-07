import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ACDG Architectural Guard: Enforcement', () {
    final uiDir = Directory('lib/src/ui');
    final domainDir = Directory('lib/src/domain');
    final dataDir = Directory('lib/src/data');
    final bffSharedDir = Directory('../../bff/shared/lib');

    // Helper para buscar todos os arquivos .dart
    Iterable<File> allDartFiles(Directory dir) => dir.existsSync()
        ? dir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))
        : [];

    test('RULE: Zero Tolerance for .valueOrNull!', () {
      final violations = <String>[];
      final targetDirs = [uiDir, domainDir, dataDir, bffSharedDir];

      for (final dir in targetDirs) {
        for (final file in allDartFiles(dir)) {
          final content = file.readAsStringSync();
          if (content.contains('.valueOrNull!')) {
            violations.add(
              '${file.path}: Found dangerous use of .valueOrNull!. Use pattern matching instead.',
            );
          }
        }
      }
      if (violations.isNotEmpty) {
        fail('Architectural Violations (Safety):\n${violations.join('\n')}');
      }
    });

    test('RULE: ViewModels MUST NOT import material.dart or dart:ui', () {
      final violations = <String>[];
      final vmFiles = allDartFiles(
        uiDir,
      ).where((f) => f.path.contains('view_model'));

      for (final file in vmFiles) {
        final content = file.readAsStringSync();
        if (content.contains("import 'package:flutter/material.dart'") ||
            content.contains("import 'dart:ui'")) {
          violations.add(
            '${file.path}: ViewModels must be pure logic. UI dependencies are forbidden.',
          );
        }
      }
      if (violations.isNotEmpty) {
        fail('Architectural Violations (MVVM): \n${violations.join('\n')}');
      }
    });

    test('RULE: Models MUST use Equatable for value equality', () {
      final violations = <String>[];
      final modelFiles = allDartFiles(
        domainDir,
      ).where((f) => !f.path.contains('.g.dart'));

      for (final file in modelFiles) {
        final content = file.readAsStringSync();
        if (content.contains('class ') &&
            !content.contains('with Equatable') &&
            !content.contains('extends Equatable')) {
          if (!content.contains('enum ') &&
              !content.contains('abstract interface class') &&
              !content.contains('abstract final class') &&
              !content.contains('mixin ')) {
            violations.add('${file.path}: Domain models must use Equatable.');
          }
        }
      }
      if (violations.isNotEmpty) {
        fail('Architectural Violations (Equality): \n${violations.join('\n')}');
      }
    });

    test('RULE: No raw JSON access in Repositories (Mandatory DTOs)', () {
      final violations = <String>[];
      final repoFiles = allDartFiles(
        dataDir,
      ).where((f) => f.path.contains('repository'));

      for (final file in repoFiles) {
        final content = file.readAsStringSync();
        // Detecção simplificada de ['key'] ou ["key"]
        final hasMapAccess = content.contains("['") || content.contains('["');
        if (hasMapAccess) {
          violations.add(
            '${file.path}: Repositories should not access raw JSON keys. Use DTOs and Mappers.',
          );
        }
      }
      if (violations.isNotEmpty) {
        fail(
          'Architectural Violations (Data Layer): \n${violations.join('\n')}',
        );
      }
    });

    test('RULE: One StatelessWidget per file and No Private Build Methods', () {
      final violations = <String>[];

      for (final file in allDartFiles(uiDir)) {
        final content = file.readAsStringSync();

        final widgetMatches = RegExp(
          r'class\s+\w+\s+extends\s+StatelessWidget',
        ).allMatches(content);
        if (widgetMatches.length > 1) {
          violations.add(
            '${file.path}: Contains ${widgetMatches.length} StatelessWidgets. Use one per file.',
          );
        }

        final buildMatches = RegExp(r'Widget\s+_\w+\s*\(').allMatches(content);
        if (buildMatches.isNotEmpty) {
          violations.add(
            '${file.path}: Contains private build methods (_build...). Extract to separate classes.',
          );
        }
      }
      if (violations.isNotEmpty) {
        fail(
          'Architectural Violations (Atomic UI): \n${violations.join('\n')}',
        );
      }
    });

    test('RULE: Strict Naming Conventions (Folder Structure)', () {
      final folders = [uiDir, dataDir, domainDir];
      final forbiddenNames = ['viewmodel', 'mapper', 'model'];

      for (final dir in folders) {
        if (!dir.existsSync()) continue;
        final subDirs = dir.listSync(recursive: true).whereType<Directory>();
        for (final sub in subDirs) {
          final folderName = sub.path.split(Platform.pathSeparator).last;
          if (forbiddenNames.contains(folderName)) {
            fail(
              'Folder name violation: ${sub.path}. Use plural names (e.g., view_models, mappers, models).',
            );
          }
        }
      }
    });

    test('RULE: Atomic State Management (No setState for Form fields)', () {
      final violations = <String>[];

      // Specifically target the modals where we know ValueNotifiers/FormStates are used
      final modalFiles = allDartFiles(uiDir).where(
        (f) =>
            f.path.contains('add_member_modal.dart') ||
            f.path.contains('family_member_modal.dart'),
      );

      for (final file in modalFiles) {
        final content = file.readAsStringSync();

        // Find usages of setState wrapping any property change logic
        // Look for setState being used for typical form fields
        final hasSetStateForFields = content.contains(
          'setState(() => _formState',
        );

        if (hasSetStateForFields) {
          violations.add(
            '${file.path}: Found instances of setState() updating a field. '
            'Rule: Use ValueListenableBuilder inside small, isolated components for atomic rebuilds instead of rebuilding the entire Modal.',
          );
        }
      }

      if (violations.isNotEmpty) {
        fail(
          'Architectural Violations (Atomic State): \n${violations.join('\n')}',
        );
      }
    });
  });
}
