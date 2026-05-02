import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import 'uuid_validation.dart';

/// Intent envelope for `POST /api/patients/{id}/family-members`.
///
/// Carries the route-level [patientId], the typed [AddFamilyMemberRequest]
/// that the Registry contract expects, plus the optional raw `cpf` and
/// `fullName` that the UseCase needs to delegate to the People Context.
///
/// The upstream contract separates the two concerns:
/// - [AddFamilyMemberRequest] carries the Registry-side fields
///   (`memberPersonId`, `relationship`, `birthDate`, `prRelationshipId`,
///   flags). When the caller provides a CPF the `memberPersonId` is empty
///   on the request — the UseCase resolves it via People Context before
///   handing it to the Registry.
/// - [cpf] and [fullName] are People Context-side inputs; they never
///   appear in the Registry request body.
///
/// PII-safety: [parseFromBody] failures MUST NOT echo raw `cpf` or
/// `fullName` — the error message only names missing structural fields.
final class AddFamilyMemberIntent with Equatable {
  const AddFamilyMemberIntent({
    required this.patientId,
    required this.request,
    this.cpf,
    this.fullName,
  });

  /// Patient whose family roster is being mutated. Comes from the route.
  final String patientId;

  /// Fully-constructed upstream request. `memberPersonId` is empty when the
  /// UseCase still needs to resolve it via People Context from CPF.
  final AddFamilyMemberRequest request;

  /// Raw CPF forwarded to People Context when present. Never logged.
  final String? cpf;

  /// Full name forwarded to People Context when present. Never logged.
  final String? fullName;

  @override
  List<Object?> get props => [patientId, request, cpf, fullName];

  /// Parses a decoded JSON body + route [patientId] into an intent.
  ///
  /// Requires `relationship`, `birthDate`, and `prRelationshipId` — the
  /// Registry-side mandatory fields. Optional fields (`memberPersonId`,
  /// `cpf`, `fullName`, `isResiding`, `isCaregiver`, `hasDisability`,
  /// `requiredDocuments`) default to sensible empty values.
  ///
  /// When the body carries a CPF the `memberPersonId` on the request starts
  /// empty — the UseCase fills it in via People Context before forwarding
  /// to the Registry.
  /// V2 (§P5): UUID validation chains into body parsing via
  /// [Result.flatMap] — no manual cast on the sealed `Result<T>`.
  static Result<AddFamilyMemberIntent> parseFromBody(
    String rawPatientId,
    Map<String, dynamic> body,
  ) =>
      validateUuidPathParam(rawPatientId, fieldName: 'patientId')
          .flatMap((patientId) => _parseBody(patientId, body));

  static Result<AddFamilyMemberIntent> _parseBody(
    String patientId,
    Map<String, dynamic> body,
  ) {
    if (body
        case {
          'relationship': final String relationship,
          'birthDate': final String birthDate,
          'prRelationshipId': final String prRelationshipId,
        }
        when relationship.isNotEmpty &&
            birthDate.isNotEmpty &&
            prRelationshipId.isNotEmpty) {
      final memberPersonId = _asString(body['memberPersonId']) ?? '';
      final request = AddFamilyMemberRequest(
        memberPersonId: memberPersonId,
        relationship: relationship,
        isResiding: _asBool(body['isResiding']),
        isCaregiver: _asBool(body['isCaregiver']),
        hasDisability: _asBool(body['hasDisability']),
        birthDate: birthDate,
        prRelationshipId: prRelationshipId,
        requiredDocuments: _asStringList(body['requiredDocuments']),
      );
      return Success(
        AddFamilyMemberIntent(
          patientId: patientId,
          request: request,
          cpf: _asNullableString(body['cpf']),
          fullName: _asNullableString(body['fullName']),
        ),
      );
    }

    final missing = <String>[];
    if (!_isNonEmptyString(body['relationship'])) missing.add('relationship');
    if (!_isNonEmptyString(body['birthDate'])) missing.add('birthDate');
    if (!_isNonEmptyString(body['prRelationshipId'])) {
      missing.add('prRelationshipId');
    }

    return Failure(
      _AddFamilyMemberParseError(
        'Invalid add family member body: missing or empty '
        '[${missing.join(', ')}]',
      ),
    );
  }

  static bool _isNonEmptyString(Object? raw) => raw is String && raw.isNotEmpty;

  static String? _asString(Object? raw) => raw is String ? raw : null;

  static String? _asNullableString(Object? raw) =>
      raw is String && raw.isNotEmpty ? raw : null;

  static bool _asBool(Object? raw) => raw is bool ? raw : false;

  static List<String> _asStringList(Object? raw) {
    if (raw is! List) return const <String>[];
    return raw.map((e) => e.toString()).toList(growable: false);
  }
}

/// Internal parse error for [AddFamilyMemberIntent.parseFromBody].
///
/// Deliberately avoids carrying any field value (CPF, full name, relationship)
/// so that the error cannot be weaponized to leak PII via logs or error
/// responses.
final class _AddFamilyMemberParseError with Equatable implements Exception {
  const _AddFamilyMemberParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}
