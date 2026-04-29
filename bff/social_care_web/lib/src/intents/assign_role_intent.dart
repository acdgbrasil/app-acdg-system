import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

/// Intent envelope for `POST /team/{memberId}/roles` — assign a role to a
/// team member.
///
/// Carries the route-level [memberId] plus the typed [AssignRoleRequest]
/// payload built from the request body.
///
/// Per ADR-019 + `PATTERN_MATCHING_POLICY.md §P2`, the DTO has 2 required
/// top-level strings (`system`, `role`) and no nested sub-DTOs, so the
/// canonical **P2 if-case manual** path is used.
final class AssignRoleIntent with Equatable {
  const AssignRoleIntent({required this.memberId, required this.request});

  final String memberId;
  final AssignRoleRequest request;

  @override
  List<Object?> get props => [memberId, request];

  /// Parses a decoded JSON body + the route [memberId] into an intent.
  ///
  /// Enforces the 2 required fields (`system`, `role`) as non-empty
  /// strings. Missing required fields produce a [Failure] whose message
  /// enumerates the field names WITHOUT echoing any raw value.
  static Result<AssignRoleIntent> parseFromBody(
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
