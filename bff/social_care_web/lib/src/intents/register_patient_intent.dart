import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

/// Intent envelope for `POST /api/patients`.
///
/// Carries the typed [RegisterPatientRequest] payload built from the request
/// body. Parsing happens via [parseFromBody] which returns a [Result] so that
/// invalid input becomes an explicit [Failure] — never an unhandled
/// `FormatException` escaping through the handler.
///
/// PII-safety: [parseFromBody] failures NEVER echo raw CPF, CNS or full name
/// back to the caller — the error only names missing structural fields. See
/// `test/intents/register_patient_intent_test.dart` for the pinned contract.
final class RegisterPatientIntent with Equatable {
  const RegisterPatientIntent({required this.request});

  /// Fully-constructed upstream request. The UseCase may still rewrite
  /// `personId` based on People Context resolution before forwarding it.
  final RegisterPatientRequest request;

  @override
  List<Object?> get props => [request];

  /// Parses a decoded JSON body into a [RegisterPatientIntent].
  ///
  /// Uses P2 if-case to enforce the presence of the minimum viable shape:
  /// [RegisterPatientRequest] requires `prRelationshipId` and
  /// `initialDiagnoses`. Missing fields produce a [_RegisterPatientParseError]
  /// whose message references only the missing field names.
  static Result<RegisterPatientIntent> parseFromBody(
    Map<String, dynamic> body,
  ) {
    if (body case {'prRelationshipId': final String pr} when pr.isNotEmpty) {
      final initialDiagnoses = _parseDiagnoses(body['initialDiagnoses']);
      final request = RegisterPatientRequest(
        personId: _asString(body['personId']) ?? '',
        prRelationshipId: pr,
        initialDiagnoses: initialDiagnoses,
        personalData: _parsePersonalData(body['personalData']),
        civilDocuments: _parseCivilDocuments(body['civilDocuments']),
        address: _parseAddress(body['address']),
        socialIdentity: _parseSocialIdentity(body['socialIdentity']),
      );
      return Success(RegisterPatientIntent(request: request));
    }

    return Failure(
      _RegisterPatientParseError(
        'Invalid register patient body: missing or empty '
        '[prRelationshipId]',
      ),
    );
  }

  static List<DiagnosisDraftDto> _parseDiagnoses(Object? raw) {
    if (raw is! List) return const <DiagnosisDraftDto>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(DiagnosisDraftDto.fromJson)
        .toList(growable: false);
  }

  static PersonalDataDraftDto? _parsePersonalData(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return PersonalDataDraftDto.fromJson(raw);
  }

  static CivilDocumentsDraftDto? _parseCivilDocuments(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return CivilDocumentsDraftDto.fromJson(raw);
  }

  static AddressDraftDto? _parseAddress(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return AddressDraftDto.fromJson(raw);
  }

  static SocialIdentityDraftDto? _parseSocialIdentity(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return SocialIdentityDraftDto.fromJson(raw);
  }

  static String? _asString(Object? raw) => raw is String ? raw : null;
}

/// Internal parse error for [RegisterPatientIntent.parseFromBody].
///
/// Deliberately avoids carrying any field value (CPF, name, document
/// numbers) so that the error cannot be weaponized to leak PII via logs or
/// error responses.
final class _RegisterPatientParseError with Equatable implements Exception {
  const _RegisterPatientParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}
