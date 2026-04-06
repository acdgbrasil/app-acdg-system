import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architectural Integrity: Widget Isolation', () {
    // Diretórios para scan
    final sourceDir = Directory('lib/src/ui');

    test('Each .dart file MUST contain at most ONE StatelessWidget', () {
      if (!sourceDir.existsSync()) return;

      final violations = <String>[];

      // Scan recursivo em busca de arquivos .dart
      final files = sourceDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in files) {
        final content = file.readAsStringSync();
        
        // Regex para encontrar declarações de StatelessWidget (públicos ou privados)
        // Procura por: class <Nome> extends StatelessWidget
        final matches = RegExp(r'class\s+\w+\s+extends\s+StatelessWidget')
            .allMatches(content);

        if (matches.length > 1) {
          violations.add(
            '${file.path} contains ${matches.length} StatelessWidgets. '
            'Rule: One widget per file to enforce Atomic Design and surgical rebuilds.',
          );
        }
      }

      if (violations.isNotEmpty) {
        fail('Architectural Violations Found:\n${violations.join('\n')}');
      }
    });

    test('Prohibition of Private Build Methods', () {
      if (!sourceDir.existsSync()) return;

      final violations = <String>[];
      final files = sourceDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in files) {
        final content = file.readAsStringSync();
        
        // Procura por métodos privados que retornam Widget: Widget _buildSomething(...)
        // Ignora o método build obrigatório: Widget build(BuildContext context)
        final matches = RegExp(r'Widget\s+_\w+\s*\(').allMatches(content);

        if (matches.isNotEmpty) {
          violations.add(
            '${file.path} contains private build methods (e.g., _build...). '
            'Rule: Extract these into separate StatelessWidget classes for performance optimization.',
          );
        }
      }

      if (violations.isNotEmpty) {
        fail('Architectural Violations Found:\n${violations.join('\n')}');
      }
    });
  });
}
