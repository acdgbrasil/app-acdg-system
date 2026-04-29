import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

/// Intent envelope for `POST /api/patients/{id}/referrals`.
///
/// Carries the route-level [patientId] plus the typed
/// [CreateReferralRequest] payload built from the request body.
/// Parsing happens via [parseFromBody] which returns a [Result] so that
/// invalid input becomes an explicit [Failure] — never an unhandled
/// `FormatException` escaping through the handler.
///
/// Per ADR-019 + `PATTERN_MATCHING_POLICY.md §P2`, the DTO has 3 required
/// top-level strings (`referredPersonId`, `destinationService`, `reason`)
/// and no nested required sub-DTOs, so the canonical **P2 if-case manual**
/// path is used (NOT `P2b` try/fromJson). Mirrors A11's
/// [UpdateIntakeInfoIntent] shape.
///
/// PII-safety (CRITICAL): [parseFromBody] failures NEVER echo raw `reason`
/// (case-history narrative) or `destinationService` (facility name) content
/// back to the caller — the error only enumerates the missing / empty
/// required field names. See
/// `test/intents/create_referral_intent_test.dart` for the pinned contract.
final class CreateReferralIntent with Equatable {
  const CreateReferralIntent({required this.patientId, required this.request});

  final String patientId;
  final CreateReferralRequest request;

  @override
  List<Object?> get props => [patientId, request];

  /// Parses a decoded JSON body + the route [patientId] into an intent.
  ///
  /// Enforces the 3 required fields (`referredPersonId`, `destinationService`,
  /// `reason`) as non-empty strings. Missing required fields produce a
  /// [Failure] whose message enumerates the field names WITHOUT echoing
  /// any raw value.
  static Result<CreateReferralIntent> parseFromBody(
    String patientId,
    Map<String, dynamic> body,
  ) {
    final referredRaw = body['referredPersonId'];
    final destinationRaw = body['destinationService'];
    final reasonRaw = body['reason'];

    final referred = referredRaw is String && referredRaw.isNotEmpty
        ? referredRaw
        : null;
    final destination = destinationRaw is String && destinationRaw.isNotEmpty
        ? destinationRaw
        : null;
    final reason = reasonRaw is String && reasonRaw.isNotEmpty
        ? reasonRaw
        : null;

    final missing = <String>[];
    if (referred == null) missing.add('referredPersonId');
    if (destination == null) missing.add('destinationService');
    if (reason == null) missing.add('reason');

    if (missing.isEmpty) {
      final request = CreateReferralRequest(
        referredPersonId: referred!,
        destinationService: destination!,
        reason: reason!,
        professionalId: _asString(body['professionalId']),
        date: _asString(body['date']),
      );
      return Success(
        CreateReferralIntent(patientId: patientId, request: request),
      );
    }

    return Failure(
      _CreateReferralParseError(
        'Invalid create-referral body: missing or empty '
        '[${missing.join(', ')}]',
      ),
    );
  }

  static String? _asString(Object? raw) => raw is String ? raw : null;
}

/// Internal parse error for [CreateReferralIntent.parseFromBody].
///
/// Deliberately avoids carrying any field value (`reason`,
/// `destinationService`, `referredPersonId`) so the error cannot be
/// weaponized to leak referral content via logs or error responses.
///
/// Note: not `const` because the message is built dynamically from the
/// list of missing required fields.
final class _CreateReferralParseError with Equatable implements Exception {
  _CreateReferralParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}
