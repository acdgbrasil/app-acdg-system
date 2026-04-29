/// `acdg_lints` — custom lint plugin for the ACDG monorepo.
///
/// Rules surfaced via `custom_lint`:
///
/// - `no_sealed_class_downcast` (error): forbids `as Subclass` when the
///   target inherits from a `sealed` class. Bypasses pattern-matching
///   exhaustiveness; see `PATTERN_MATCHING_POLICY.md §P5`. Test files are
///   exempt by design.
///
/// Future rules (planned in `.pipeline/.../A22-acdg-lints/`):
///
/// - `catch_without_stack_in_adapter`
/// - `intent_parse_must_accept_obs`
/// - `parse_error_must_be_private`
/// - `prefer_logical_pattern_grouping`
library;

import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/no_sealed_class_downcast.dart';

PluginBase createPlugin() => _AcdgLintsPlugin();

class _AcdgLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    NoSealedClassDowncast(),
  ];
}
