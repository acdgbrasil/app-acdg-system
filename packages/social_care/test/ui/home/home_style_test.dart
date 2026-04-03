import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Home Components Style & Architecture TDD', () {
    final homeDir = Directory(p.join('lib', 'src', 'ui', 'home'));

    test('Home components should not use hardcoded Colors', () {
      final files = homeDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
      
      for (final file in files) {
        final content = file.readAsStringSync();
        expect(content.contains(RegExp(r'Color\(0x[0-9a-fA-F]+\)')), isFalse, 
          reason: 'Hardcoded Color found in ${file.path}. Use AppColors from design_system.');
      }
    });

    test('Home page should use Riverpod, not Provider legacy', () {
      final file = File(p.join(homeDir.path, 'view', 'page', 'home_page.dart'));
      if (!file.existsSync()) return;

      final content = file.readAsStringSync();
      expect(content.contains('context.read<HomeViewModel>()'), isFalse, 
        reason: 'Legacy Provider usage detected. Use ConsumerWidget and ref.watch/read.');
    });
  });
}
