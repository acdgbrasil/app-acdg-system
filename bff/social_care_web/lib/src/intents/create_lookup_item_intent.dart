import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

/// Intent envelope for `POST /lookups/{tableName}`.
///
/// Carries the route-level [tableName] plus the typed
/// [CreateLookupItemRequest] payload built from the request body.
/// Parsing happens via [parseFromBody] which returns a [Result] so that
/// invalid input becomes an explicit [Failure] — never an unhandled
/// `FormatException` escaping through the handler.
///
/// Per ADR-019 + `PATTERN_MATCHING_POLICY.md §P2`, the DTO has 2 required
/// top-level strings (`codigo`, `descricao`) and no nested required
/// sub-DTOs, so the canonical **P2 if-case manual** path is used.
///
/// PII-safety: domain codes are not PII-dense but the canon still forbids
/// echoing raw values; parse errors only enumerate the missing structural
/// field names. See `test/intents/create_lookup_item_intent_test.dart` for
/// the pinned contract.
final class CreateLookupItemIntent with Equatable {
  const CreateLookupItemIntent({
    required this.tableName,
    required this.request,
  });

  final String tableName;
  final CreateLookupItemRequest request;

  @override
  List<Object?> get props => [tableName, request];

  /// Parses a decoded JSON body + the route [tableName] into an intent.
  ///
  /// Enforces both required fields (`codigo`, `descricao`) as non-empty
  /// strings. Missing required fields produce a [Failure] whose message
  /// enumerates the field names WITHOUT echoing any raw value.
  static Result<CreateLookupItemIntent> parseFromBody(
    String tableName,
    Map<String, dynamic> body,
  ) {
    final codigoRaw = body['codigo'];
    final descricaoRaw = body['descricao'];

    final codigo = codigoRaw is String && codigoRaw.isNotEmpty
        ? codigoRaw
        : null;
    final descricao = descricaoRaw is String && descricaoRaw.isNotEmpty
        ? descricaoRaw
        : null;

    final missing = <String>[];
    if (codigo == null) missing.add('codigo');
    if (descricao == null) missing.add('descricao');

    if (missing.isEmpty) {
      final request = CreateLookupItemRequest(
        codigo: codigo!,
        descricao: descricao!,
      );
      return Success(
        CreateLookupItemIntent(tableName: tableName, request: request),
      );
    }

    return Failure(
      _CreateLookupItemParseError(
        'Invalid create-lookup-item body: missing or empty '
        '[${missing.join(', ')}]',
      ),
    );
  }
}

/// Internal parse error for [CreateLookupItemIntent.parseFromBody].
///
/// Deliberately avoids carrying any field value (`codigo`, `descricao`)
/// so the error cannot be weaponized to leak lookup content via logs or
/// error responses.
///
/// Note: not `const` because the message is built dynamically from the
/// list of missing required fields.
final class _CreateLookupItemParseError with Equatable implements Exception {
  _CreateLookupItemParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}
