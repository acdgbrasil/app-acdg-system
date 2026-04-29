import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Forbids downcasting a `sealed` class to one of its concrete variants.
///
/// **Why:** sealed classes exist so the compiler can prove exhaustiveness
/// via switch / pattern matching. A manual `as Subclass` cast bypasses
/// that proof — it duplicates a runtime check that pattern matching would
/// have done at compile time AND silently breaks if a new variant is later
/// added to the sealed hierarchy. See `PATTERN_MATCHING_POLICY.md §P5`.
///
/// **Trigger:** any `AsExpression` (`x as T`) where `T` is a subclass of a
/// type whose declaration carries the `sealed` modifier.
///
/// **Exemptions:** files under `test/`, `tests/`, `test_driver/`,
/// `integration_test/`, and any `*_test.dart` are NOT linted. In tests
/// the cast is a legitimate fail-fast assertion idiom — a `TypeError`
/// surfaces clearly in the test runner output. Defensive switching in
/// tests, in contrast, can mask regressions silently.
class NoSealedClassDowncast extends DartLintRule {
  NoSealedClassDowncast() : super(code: _code);

  static const _code = LintCode(
    name: 'no_sealed_class_downcast',
    problemMessage:
        'Manual downcast on sealed class bypasses pattern matching '
        'exhaustiveness — use switch / map / flatMap / combineWith instead.',
    correctionMessage:
        'Replace `(value as Subclass).field` with a switch over the sealed '
        'type, or use one of the Result combinators (.map, .flatMap, '
        'combineWith). See PATTERN_MATCHING_POLICY.md §P5.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (_isTestFile(resolver.path)) return;

    context.registry.addAsExpression((node) {
      final targetType = node.type.type;
      if (targetType is! InterfaceType) return;

      if (!_hasSealedAncestor(targetType.element)) return;

      reporter.atNode(node, _code);
    });
  }

  /// True when the file path looks like a test file or lives inside a
  /// canonical test directory.
  static bool _isTestFile(String path) {
    final normalized = path.replaceAll(r'\', '/');
    if (normalized.endsWith('_test.dart')) return true;
    return normalized.contains('/test/') ||
        normalized.contains('/tests/') ||
        normalized.contains('/test_driver/') ||
        normalized.contains('/integration_test/');
  }

  /// True when [element] is a strict subtype of an [InterfaceElement] whose
  /// declaration has the `sealed` modifier.
  ///
  /// Walks the entire `allSupertypes` chain so an indirect descendant
  /// (e.g. `class Cat extends DomesticAnimal` where `sealed class Animal`
  /// is two levels up) is still flagged. Only `ClassElement` declarations
  /// can carry the `sealed` modifier — enums, mixins, and extension types
  /// are short-circuited.
  static bool _hasSealedAncestor(InterfaceElement element) {
    for (final supertype in element.allSupertypes) {
      final superElement = supertype.element;
      if (superElement is ClassElement && superElement.isSealed) {
        return true;
      }
    }
    return false;
  }
}
