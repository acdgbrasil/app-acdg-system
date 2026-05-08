import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import 'uuid_validation.dart';

/// Intent envelope for `PUT /lookups/{tableName}/{id}` — partial update.
///
/// P2-tolerant variant: both body fields (`codigo`, `descricao`) are
/// OPTIONAL. The body parsing portion is **total** (never fails) —
/// missing or type-mismatched values collapse to `null`, an empty `{}`
/// body yields a Success with both fields null (upstream no-op).
///
/// Path discipline (A23 / §P5): the route is `{tableName}/{itemId}`.
/// `tableName` is a literal (e.g. `dominio_parentesco`) and is NOT a
/// UUID — it passes through as-is. `itemId` IS validated as UUID v4 via
/// `validateUuidPathParam`, chaining via [Result.map] (no manual cast on
/// the sealed `Result<T>`).
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

  /// Parses a partial update body + route params. Body parse is total
  /// once UUID validation succeeds.
  ///
  /// V2 (§P5): only `rawItemId` is UUID-validated. `tableName` is
  /// pass-through. Chain via [Result.map] — no manual cast.
  static Result<UpdateLookupItemIntent> parseFromBody(
    String tableName,
    String rawItemId,
    Map<String, dynamic> body,
  ) => validateUuidPathParam(rawItemId, fieldName: 'itemId').map(
    (itemId) => UpdateLookupItemIntent(
      tableName: tableName,
      itemId: itemId,
      request: UpdateLookupItemRequest(
        codigo: _asString(body['codigo']),
        descricao: _asString(body['descricao']),
      ),
    ),
  );

  static String? _asString(Object? raw) => raw is String ? raw : null;
}
