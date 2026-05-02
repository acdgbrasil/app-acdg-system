import 'package:test/test.dart';

import 'package:social_care_web/src/observability/observability_context.dart';

/// Shared helpers for asserting on [ObservabilityContext] breadcrumbs in tests.
///
/// Wave 1 MUST implement [ObservabilityContext.noop] such that it captures
/// breadcrumbs in a readable list ([ObservabilityContext.breadcrumbs]) so that
/// tests can verify what was emitted without wiring AcdgLogger/Sentry.

/// Matcher that asserts a breadcrumb with the given [event] name was recorded.
Matcher hasEvent(String event) => predicate<BreadcrumbRecord>(
  (record) => record.event == event,
  'breadcrumb event equals "$event"',
);

/// Matcher that asserts a breadcrumb with the given [event] name AND data
/// entries was recorded. Data match is a subset check — keys not listed are
/// allowed to exist.
Matcher hasEventWithData(String event, Map<String, Object?> expected) =>
    predicate<BreadcrumbRecord>((record) {
      if (record.event != event) return false;
      for (final entry in expected.entries) {
        if (record.data[entry.key] != entry.value) return false;
      }
      return true;
    }, 'breadcrumb event equals "$event" with data subset $expected');
