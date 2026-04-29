import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

/// Intent envelope for `PATCH /lookups/{tableName}/{id}/toggle`.
///
/// Carries the route-level [tableName] + [itemId] plus the typed
/// [ToggleLookupItemRequest] payload built from the request body.
///
/// Per `PATTERN_MATCHING_POLICY.md §P2`, the DTO has a single required
/// boolean (`active`). Because the failure message is fixed (single
/// field), `_ToggleLookupItemParseError` IS `const`.
final class ToggleLookupItemIntent with Equatable {
  const ToggleLookupItemIntent({
    required this.tableName,
    required this.itemId,
    required this.request,
  });

  final String tableName;
  final String itemId;
  final ToggleLookupItemRequest request;

  @override
  List<Object?> get props => [tableName, itemId, request];

  /// Parses a decoded JSON body + the route [tableName] + [itemId] into
  /// an intent. `active` MUST be a `bool` — missing or type-mismatched
  /// values produce a [Failure] with the const literal message.
  static Result<ToggleLookupItemIntent> parseFromBody(
    String tableName,
    String itemId,
    Map<String, dynamic> body,
  ) {
    if (body case {'active': final bool active}) {
      return Success(
        ToggleLookupItemIntent(
          tableName: tableName,
          itemId: itemId,
          request: ToggleLookupItemRequest(active: active),
        ),
      );
    }
    return Failure(
      const _ToggleLookupItemParseError(
        'Invalid toggle-lookup-item body: missing or invalid [active]',
      ),
    );
  }
}

/// Internal, PII-safe parse error for [ToggleLookupItemIntent.parseFromBody].
///
/// `const` because the message is a fixed literal — there is only one
/// required field (`active`) so no dynamic enumeration is needed.
final class _ToggleLookupItemParseError with Equatable implements Exception {
  const _ToggleLookupItemParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}
