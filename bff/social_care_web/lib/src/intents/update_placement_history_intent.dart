import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../observability/observability_context.dart';

/// Intent for `PUT /api/patients/{id}/placement-history`.
///
/// Wraps the route-level [patientId] with the typed
/// [UpdatePlacementHistoryRequest] body. Parsing delegates to the
/// `json_serializable`-generated `fromJson` — wrapped in try/catch so the
/// handler receives a [Result] instead of an exception (see A10 REPORT,
/// P2b canon adopted here because):
/// - Top-level DTO has 0 required fields (`registries` defaults to `[]`).
/// - Nested sub-DTOs carry their own required tri-tuples
///   (`RegistryDraftDto`: memberId/startDate/reason).
/// - PII-dense free-narrative fields (`homeLossReport`,
///   `thirdPartyGuardReport`, `RegistryDraftDto.reason`) whose manual P2
///   enumeration would duplicate 40+ lines of `fromJson` AND risk echoing
///   values via `CheckedFromJsonException.toString()`.
///
/// The resulting error message is structural and PII-safe: it never
/// enumerates offending fields nor echoes caller-supplied values.
final class UpdatePlacementHistoryIntent with Equatable {
  const UpdatePlacementHistoryIntent({
    required this.patientId,
    required this.request,
  });

  final String patientId;
  final UpdatePlacementHistoryRequest request;

  @override
  List<Object?> get props => [patientId, request];

  /// Parses a decoded JSON body + the route [patientId] into an intent.
  ///
  /// Any failure in the underlying `fromJson` (missing/wrong-typed fields,
  /// malformed nested DTOs) collapses to a single [Failure] whose message
  /// is the structural literal pinned by Wave 0. The optional [obs] routes
  /// the original cause + stack trace via `logError` — the public
  /// [Failure] remains PII-safe.
  static Result<UpdatePlacementHistoryIntent> parseFromBody(
    String patientId,
    Map<String, dynamic> body, {
    ObservabilityContext? obs,
  }) {
    try {
      final request = UpdatePlacementHistoryRequest.fromJson(body);
      return Success(
        UpdatePlacementHistoryIntent(patientId: patientId, request: request),
      );
    } catch (e, st) {
      obs?.logError(
        'protection.placement_history.parse_failed',
        cause: e,
        stack: st,
      );
      return Failure(
        const _UpdatePlacementHistoryParseError(
          'Invalid update-placement-history body: '
          'missing or malformed required fields',
        ),
      );
    }
  }
}

/// Internal, PII-safe parse error for
/// [UpdatePlacementHistoryIntent.parseFromBody].
///
/// The message is a compile-time constant literal — it never enumerates
/// offending fields nor echoes caller-supplied values (`homeLossReport`,
/// `thirdPartyGuardReport`, `RegistryDraftDto.reason`, `memberId`).
final class _UpdatePlacementHistoryParseError
    with Equatable
    implements Exception {
  const _UpdatePlacementHistoryParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}
