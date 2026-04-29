import 'package:core_contracts/core_contracts.dart';

/// Intent envelope for `DELETE /api/patients/{id}/family-members/{memberId}`.
///
/// No request body — only the two route params. [parseFromParams] returns a
/// [Result] for symmetry with the other A09 intents so the handler can
/// short-circuit via the same P1 switch shape.
///
/// Both ids must be non-empty; otherwise the parser returns a [Failure]
/// carrying a [_RemoveFamilyMemberParseError] with a purely structural
/// message.
final class RemoveFamilyMemberIntent with Equatable {
  const RemoveFamilyMemberIntent({
    required this.patientId,
    required this.memberId,
  });

  final String patientId;
  final String memberId;

  @override
  List<Object?> get props => [patientId, memberId];

  /// Parses the route params into an intent. Both ids are required.
  static Result<RemoveFamilyMemberIntent> parseFromParams({
    required String patientId,
    required String memberId,
  }) {
    final missing = <String>[];
    if (patientId.isEmpty) missing.add('patientId');
    if (memberId.isEmpty) missing.add('memberId');

    if (missing.isEmpty) {
      return Success(
        RemoveFamilyMemberIntent(patientId: patientId, memberId: memberId),
      );
    }

    return Failure(
      _RemoveFamilyMemberParseError(
        'Invalid remove family member params: missing or empty '
        '[${missing.join(', ')}]',
      ),
    );
  }
}

/// Internal parse error for [RemoveFamilyMemberIntent.parseFromParams].
final class _RemoveFamilyMemberParseError with Equatable implements Exception {
  const _RemoveFamilyMemberParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}
