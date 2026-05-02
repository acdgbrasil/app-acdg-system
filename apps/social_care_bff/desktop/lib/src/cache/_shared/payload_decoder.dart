/// Helper for decoding batch JSON-blob cache rows possibly off the
/// main isolate.
///
/// Counterpart to `RemoteBase.mapListPossiblyInIsolate` (remote layer)
/// — but adapted for the cache layer's row shape: each Drift row holds
/// a JSON `payload` string that needs `jsonDecode` + `Dto.fromJson` to
/// rebuild the typed DTO.
///
/// Per `handbook/architecture/CONCURRENCY_AND_PERFORMANCE_POLICY.md` §C1
/// + `handbook/audit/2026-05-01-bff-comprehensive/05-isolates-opportunities.md` T2.2:
/// large list reads (`listSummaries`, `searchSummaries`,
/// `listByPatient`, etc.) above the threshold delegate the per-row
/// decode + map to a background isolate. Single-row reads (`findById`)
/// stay inline (audit anti-pattern A2 — sub-ms cost).
///
/// **Sendable contract:** [fromJson] MUST be a top-level function or
/// static-method tear-off (e.g. `PatientResponse.fromJson`). Closures
/// with captured state are NOT sendable.
///
/// **Behavior contract:** the returned `List<T>` is observationally
/// identical to:
/// ```dart
/// payloads
///     .map((p) => fromJson(jsonDecode(p) as Map<String, dynamic>))
///     .toList()
/// ```
/// — same length, same order, same field values. Only the executing
/// isolate differs.
///
/// Introduced by T2.2 (2026-05-01).
library;

import 'dart:convert';
import 'dart:isolate';

/// Threshold above which the helper delegates to [Isolate.run].
/// Matches the policy guidance and `RemoteBase.isolateMappingThreshold`.
const int kCacheDecodeIsolateThreshold = 50;

/// Decodes a batch of JSON-blob payloads into typed DTOs, possibly off
/// the main isolate.
///
/// When [payloads] has more than [threshold] entries, the entire decode
/// + map runs inside [Isolate.run]. Below or equal to the threshold,
/// the work runs synchronously on the calling isolate to avoid the
/// spawn overhead.
Future<List<T>> decodePayloadsPossiblyInIsolate<T>(
  List<String> payloads,
  T Function(Map<String, dynamic>) fromJson, {
  int threshold = kCacheDecodeIsolateThreshold,
}) async {
  if (payloads.length <= threshold) {
    return payloads
        .map((p) => fromJson(jsonDecode(p) as Map<String, dynamic>))
        .toList();
  }
  return Isolate.run<List<T>>(
    () => payloads
        .map((p) => fromJson(jsonDecode(p) as Map<String, dynamic>))
        .toList(),
  );
}
