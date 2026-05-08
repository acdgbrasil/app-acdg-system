import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import 'uuid_validation.dart';

/// Intent envelope for `PUT /api/patients/{id}/intake`.
///
/// Carries the route-level [patientId] plus the typed
/// [RegisterIntakeInfoRequest] payload built from the request body.
/// Parsing happens via [parseFromBody] which returns a [Result] so that
/// invalid input becomes an explicit [Failure] — never an unhandled
/// `FormatException` escaping through the handler.
///
/// Per ADR-019 + `PATTERN_MATCHING_POLICY.md §P2`, the DTO has only 2
/// required fields (`ingressTypeId`, `serviceReason`) and no dense
/// PII-sensitive identifier set, so the canonical **P2 if-case manual**
/// path is used (NOT `P2b` try/fromJson).
///
/// PII-safety: [parseFromBody] failures NEVER echo raw `originName`,
/// `originContact` or `serviceReason` content back to the caller — the error
/// only enumerates the missing / empty required field names. See
/// `test/intents/update_intake_info_intent_test.dart` for the pinned contract.
final class UpdateIntakeInfoIntent with Equatable {
  const UpdateIntakeInfoIntent({
    required this.patientId,
    required this.request,
  });

  final String patientId;
  final RegisterIntakeInfoRequest request;

  @override
  List<Object?> get props => [patientId, request];

  /// Parses a decoded JSON body + the route [rawPatientId] into an intent.
  ///
  /// V2 (§P5): UUID validation chains into body parsing via
  /// [Result.flatMap] — no manual cast. Body parser enforces both required
  /// fields (`ingressTypeId`, `serviceReason`) as non-empty strings.
  /// `linkedSocialPrograms` degrades to an empty list when absent or
  /// malformed — it is treated as an optional collection. Missing required
  /// fields produce a [Failure] whose message enumerates the field names
  /// WITHOUT echoing any raw value.
  static Result<UpdateIntakeInfoIntent> parseFromBody(
    String rawPatientId,
    Map<String, dynamic> body,
  ) => validateUuidPathParam(
    rawPatientId,
    fieldName: 'patientId',
  ).flatMap((patientId) => _parseBody(patientId, body));

  static Result<UpdateIntakeInfoIntent> _parseBody(
    String patientId,
    Map<String, dynamic> body,
  ) {
    final ingressTypeIdRaw = body['ingressTypeId'];
    final serviceReasonRaw = body['serviceReason'];

    final ingressTypeId =
        ingressTypeIdRaw is String && ingressTypeIdRaw.isNotEmpty
        ? ingressTypeIdRaw
        : null;
    final serviceReason =
        serviceReasonRaw is String && serviceReasonRaw.isNotEmpty
        ? serviceReasonRaw
        : null;

    final missing = <String>[];
    if (ingressTypeId == null) missing.add('ingressTypeId');
    if (serviceReason == null) missing.add('serviceReason');

    if (missing.isEmpty) {
      final request = RegisterIntakeInfoRequest(
        ingressTypeId: ingressTypeId!,
        serviceReason: serviceReason!,
        originName: _asString(body['originName']),
        originContact: _asString(body['originContact']),
        linkedSocialPrograms: _parseLinkedPrograms(
          body['linkedSocialPrograms'],
        ),
      );
      return Success(
        UpdateIntakeInfoIntent(patientId: patientId, request: request),
      );
    }

    return Failure(
      _UpdateIntakeInfoParseError(
        'Invalid update-intake body: missing or empty '
        '[${missing.join(', ')}]',
      ),
    );
  }

  static List<ProgramLinkDraftDto> _parseLinkedPrograms(Object? raw) {
    if (raw is! List) return const <ProgramLinkDraftDto>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ProgramLinkDraftDto.fromJson)
        .toList(growable: false);
  }

  static String? _asString(Object? raw) => raw is String ? raw : null;
}

/// Internal parse error for [UpdateIntakeInfoIntent.parseFromBody].
///
/// Deliberately avoids carrying any field value (`originName`,
/// `originContact`, `serviceReason`) so the error cannot be weaponized to
/// leak intake/service-reason content via logs or error responses.
///
/// Note: not `const` because the message is built dynamically from the
/// list of missing required fields.
final class _UpdateIntakeInfoParseError with Equatable implements Exception {
  _UpdateIntakeInfoParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}
