import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import 'uuid_validation.dart';

/// Intent envelope for `POST /team/{memberId}/roles` — assign a role to a
/// team member.
///
/// Carries the route-level [memberId] plus the typed [AssignRoleRequest]
/// payload built from the request body. [parseFromBody] validates the
/// path parameter as a canonical UUID v4 (per A23 — `validateUuidPathParam`)
/// and then enforces the presence of the 2 required body fields
/// (`system`, `role`) using the canonical P2 if-case.
///
/// V2 (§P5): UUID validation chains into body parsing via
/// [Result.flatMap] — no manual cast on the sealed `Result<T>`. The UUID
/// gate fires BEFORE body parsing, so a malformed path id surfaces a
/// [UuidPathParamError] even when the body would also fail.
final class AssignRoleIntent with Equatable {
  const AssignRoleIntent({required this.memberId, required this.request});

  final String memberId;
  final AssignRoleRequest request;

  @override
  List<Object?> get props => [memberId, request];

  /// Parses a decoded JSON body + the route [rawMemberId] into an intent.
  ///
  /// A non-UUID-v4 [rawMemberId] short-circuits with a
  /// [UuidPathParamError] via `flatMap`. Missing or empty `system` /
  /// `role` then produce a [Failure] whose message enumerates the
  /// missing field names WITHOUT echoing any raw value.
  static Result<AssignRoleIntent> parseFromBody(
    String rawMemberId,
    Map<String, dynamic> body,
  ) => validateUuidPathParam(
    rawMemberId,
    fieldName: 'memberId',
  ).flatMap((memberId) => _parseBody(memberId, body));

  static Result<AssignRoleIntent> _parseBody(
    String memberId,
    Map<String, dynamic> body,
  ) {
    final systemRaw = body['system'];
    final roleRaw = body['role'];

    final system = systemRaw is String && systemRaw.isNotEmpty
        ? systemRaw
        : null;
    final role = roleRaw is String && roleRaw.isNotEmpty ? roleRaw : null;

    final missing = <String>[];
    if (system == null) missing.add('system');
    if (role == null) missing.add('role');

    if (missing.isEmpty) {
      return Success(
        AssignRoleIntent(
          memberId: memberId,
          request: AssignRoleRequest(system: system!, role: role!),
        ),
      );
    }

    return Failure(
      _AssignRoleParseError(
        'Invalid assign-role body: missing or empty [${missing.join(', ')}]',
      ),
    );
  }
}

/// Internal parse error for [AssignRoleIntent.parseFromBody].
///
/// Note: not `const` because the message is built dynamically from the
/// list of missing required fields.
final class _AssignRoleParseError with Equatable implements Exception {
  _AssignRoleParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}
