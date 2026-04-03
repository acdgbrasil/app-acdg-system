import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Home Module Arch TDD (Mission 009.1)', () {
    final homeDir = Directory(p.join('lib', 'src', 'ui', 'home'));

    test('Home components should NOT use hardcoded Colors', () {
      final files = homeDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
      
      for (final file in files) {
        final content = file.readAsStringSync();
        expect(
          content.contains(RegExp(r'Color\(0x[0-9a-fA-F]+\)')), 
          isFalse, 
          reason: 'Hardcoded Color found in ${file.path}. The Home module MUST use AppColors from the design_system.'
        );
      }
    });

    test('HomePage should NOT use Provider legacy methods', () {
      final file = File(p.join(homeDir.path, 'view', 'page', 'home_page.dart'));
      if (!file.existsSync()) return;

      final content = file.readAsStringSync();
      expect(
        content.contains('context.read<HomeViewModel>()'), 
        isFalse, 
        reason: 'Legacy Provider usage detected in home_page.dart. MUST use ConsumerStatefulWidget and ref.watch/read.'
      );
      expect(
        content.contains('context.watch<'), 
        isFalse, 
        reason: 'Legacy Provider usage detected in home_page.dart. MUST use ConsumerStatefulWidget and ref.watch/read.'
      );
    });

    test('HomePage should NOT use setState for business logic (Search/Tabs)', () {
      final file = File(p.join(homeDir.path, 'view', 'page', 'home_page.dart'));
      if (!file.existsSync()) return;

      final content = file.readAsStringSync();
      // The search or tab state should be in the ViewModel
      expect(
        content.contains(RegExp(r'setState\(\(\) \{\}\);')), 
        isFalse, 
        reason: 'Empty setState found in home_page.dart. This is a hack to force rebuilds. Use ListenableBuilder and ViewModel state.'
      );
      expect(
        content.contains(RegExp(r'setState\(\(\) => _activeTab')), 
        isFalse, 
        reason: 'Local state _activeTab found in View. Move tab state to HomeViewModel.'
      );
    });
  });
}
