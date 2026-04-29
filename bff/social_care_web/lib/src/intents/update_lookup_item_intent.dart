import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

/// Intent envelope for `PUT /lookups/{tableName}/{id}` — partial update.
///
/// P2-tolerant variant (first use in the monorepo): both DTO fields
/// (`codigo`, `descricao`) are OPTIONAL. [parseFromBody] is a **total
/// function** — it never returns [Failure]. Missing or type-mismatched
/// values silently collapse to `null` via the `_asString` helper; an
/// empty `{}` body yields a Success with both fields null (upstream no-op).
///
/// Because parse never fails, there is NO `_UpdateLookupItemParseError`
/// class; the handler routes JSON-level malformed input through the
/// `INVALID_JSON` code from `_readJsonBody` before this parser runs.
final class UpdateLookupItemIntent with Equatable {
  const UpdateLookupItemIntent({
    required this.tableName,
    required this.itemId,
    required this.request,
  });

  final String tableName;
  final String itemId;
  final UpdateLookupItemRequest request;

  @override
  List<Object?> get props => [tableName, itemId, request];

  /// Parses a partial update body. Both fields are optional per contract.
  /// Parse is total: body `{}` yields an all-null request (upstream no-op).
  static Result<UpdateLookupItemIntent> parseFromBody(
    String tableName,
    String itemId,
    Map<String, dynamic> body,
  ) {
    final request = UpdateLookupItemRequest(
      codigo: _asString(body['codigo']),
      descricao: _asString(body['descricao']),
    );
    return Success(
      UpdateLookupItemIntent(
        tableName: tableName,
        itemId: itemId,
        request: request,
      ),
    );
  }

  static String? _asString(Object? raw) => raw is String ? raw : null;
}
