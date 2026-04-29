import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import 'uuid_validation.dart';

/// Intent envelope for `POST /api/patients/{id}/violations`.
///
/// Carries the route-level [patientId] plus the typed
/// [ReportRightsViolationRequest] payload built from the request body.
/// Parsing happens via [parseFromBody] which returns a [Result] so that
/// invalid input becomes an explicit [Failure] — never an unhandled
/// `FormatException` escaping through the handler.
///
/// Per ADR-019 + `PATTERN_MATCHING_POLICY.md §P2`, the DTO has 3 required
/// top-level strings (`victimId`, `violationType`, `descriptionOfFact`) and
/// no nested required sub-DTOs, so the canonical **P2 if-case manual** path
/// is used (NOT `P2b` try/fromJson). Mirrors A11's [UpdateIntakeInfoIntent]
/// shape.
///
/// PII-safety (CRITICAL — narrative against paciente, often a child):
/// - `descriptionOfFact` carries raw description of violation.
/// - `actionsTaken` carries raw intervention notes.
/// - `victimId` is a UUID but still PII-adjacent.
/// Parse errors MUST NEVER echo any of these field values — only the
/// structurally-missing field NAMES. See
/// `test/intents/report_rights_violation_intent_test.dart` for the pinned
/// contract.
final class ReportRightsViolationIntent with Equatable {
  const ReportRightsViolationIntent({
    required this.patientId,
    required this.request,
  });

  final String patientId;
  final ReportRightsViolationRequest request;

  @override
  List<Object?> get props => [patientId, request];

  /// Parses a decoded JSON body + the route [rawPatientId] into an intent.
  ///
  /// V2 (§P5): UUID validation chains into body parsing via
  /// [Result.flatMap] — no manual cast. Body parser enforces the 3
  /// required fields (`victimId`, `violationType`, `descriptionOfFact`)
  /// as non-empty strings. Optional fields (`violationTypeId`,
  /// `reportDate`, `incidentDate`, `actionsTaken`) are carried through
  /// verbatim when present; missing values degrade to `null`. Missing
  /// required fields produce a [Failure] whose message enumerates the
  /// field NAMES WITHOUT echoing any raw value.
  static Result<ReportRightsViolationIntent> parseFromBody(
    String rawPatientId,
    Map<String, dynamic> body,
  ) =>
      validateUuidPathParam(rawPatientId, fieldName: 'patientId')
          .flatMap((patientId) => _parseBody(patientId, body));

  static Result<ReportRightsViolationIntent> _parseBody(
    String patientId,
    Map<String, dynamic> body,
  ) {
    final victimRaw = body['victimId'];
    final violationTypeRaw = body['violationType'];
    final descriptionRaw = body['descriptionOfFact'];

    final victimId = victimRaw is String && victimRaw.isNotEmpty
        ? victimRaw
        : null;
    final violationType =
        violationTypeRaw is String && violationTypeRaw.isNotEmpty
        ? violationTypeRaw
        : null;
    final descriptionOfFact =
        descriptionRaw is String && descriptionRaw.isNotEmpty
        ? descriptionRaw
        : null;

    final missing = <String>[];
    if (victimId == null) missing.add('victimId');
    if (violationType == null) missing.add('violationType');
    if (descriptionOfFact == null) missing.add('descriptionOfFact');

    if (missing.isEmpty) {
      final request = ReportRightsViolationRequest(
        victimId: victimId!,
        violationType: violationType!,
        descriptionOfFact: descriptionOfFact!,
        violationTypeId: _asString(body['violationTypeId']),
        reportDate: _asString(body['reportDate']),
        incidentDate: _asString(body['incidentDate']),
        actionsTaken: _asString(body['actionsTaken']),
      );
      return Success(
        ReportRightsViolationIntent(patientId: patientId, request: request),
      );
    }

    return Failure(
      _ReportRightsViolationParseError(
        'Invalid report-violation body: missing or empty '
        '[${missing.join(', ')}]',
      ),
    );
  }

  static String? _asString(Object? raw) => raw is String ? raw : null;
}

/// Internal parse error for [ReportRightsViolationIntent.parseFromBody].
///
/// Deliberately avoids carrying any field value (`descriptionOfFact`,
/// `actionsTaken`, `victimId`) so the error cannot be weaponized to leak
/// violation narrative or victim identification via logs or error responses.
///
/// Note: not `const` because the message is built dynamically from the
/// list of missing required fields.
final class _ReportRightsViolationParseError
    with Equatable
    implements Exception {
  _ReportRightsViolationParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}
