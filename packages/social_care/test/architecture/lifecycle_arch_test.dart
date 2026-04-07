import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Lifecycle & Optimization Arch TDD (Mission PENDENCIAS)', () {
    test('HomeViewModel must NOT auto-load in constructor', () {
      final file = File(
        p.join('lib', 'src', 'ui', 'home', 'viewModel', 'home_view_model.dart'),
      );
      if (!file.existsSync()) return;

      final content = file.readAsStringSync();

      // We look for 'load.execute();' inside the constructor block
      // A simple regex to check if it's called inside the class initialization
      expect(
        content.contains(RegExp(r'load\.execute\(\);')),
        isFalse,
        reason:
            'CRITICAL FAILURE: load.execute() found in HomeViewModel. ViewModels must NOT trigger network requests in their constructors. Delegate this to the View\'s initState or lifecycle hooks.',
      );
    });

    test('HomePage must explicitly call load.execute on mount', () {
      final file = File(
        p.join('lib', 'src', 'ui', 'home', 'view', 'page', 'home_page.dart'),
      );
      if (!file.existsSync()) return;

      final content = file.readAsStringSync();

      expect(
        content.contains(RegExp(r'load\.execute\(\)')),
        isTrue,
        reason:
            'CRITICAL FAILURE: HomePage must call load.execute() when it mounts (e.g. inside initState or via a post-frame callback).',
      );
    });
  });
}
