import 'package:core_contracts/core_contracts.dart';

import 'uuid_validation.dart';

/// Intent envelope for `DELETE /api/patients/{id}/family-members/{memberId}`.
///
/// No request body — only the two route params, both validated as UUID v4
/// via [validateUuidPathParam]. Returns a [Result] for symmetry with the
/// other A09 intents so the handler can short-circuit via the same P1
/// switch shape; failure modes are exclusively [UuidPathParamError]
/// (PII-safe — only the fieldName surfaces, never the raw input).
final class RemoveFamilyMemberIntent with Equatable {
  const RemoveFamilyMemberIntent({
    required this.patientId,
    required this.memberId,
  });

  final String patientId;
  final String memberId;

  @override
  List<Object?> get props => [patientId, memberId];

  /// Parses the route params into an intent. Both ids must be UUID v4.
  ///
  /// V2 (§P5): uses the `Result2Combinator.combineWith` extension from
  /// `core_contracts/result_combinators.dart`. Short-circuits on the first
  /// failure (left → right) preserving its `error` + `stackTrace`. No
  /// manual cast on the sealed `Result<T>`.
  ///
  /// The named-args signature is kept (deviation from the verbatim 2-id
  /// Template B) — the call site in `RegistryFamilyHandler._handleRemove`
  /// already uses named args.
  static Result<RemoveFamilyMemberIntent> parseFromParams({
    required String rawPatientId,
    required String rawMemberId,
  }) {
    final p = validateUuidPathParam(rawPatientId, fieldName: 'patientId');
    final m = validateUuidPathParam(rawMemberId, fieldName: 'memberId');
    return (p, m).combineWith(
      (patientId, memberId) =>
          RemoveFamilyMemberIntent(patientId: patientId, memberId: memberId),
    );
  }
}
