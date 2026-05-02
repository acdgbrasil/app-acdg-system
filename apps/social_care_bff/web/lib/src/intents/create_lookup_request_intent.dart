import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

/// Intent envelope for `POST /lookup-requests` — user proposes a new lookup
/// item via a governance request.
///
/// Wraps the typed [CreateLookupRequestRequest] payload built from the
/// request body. This intent has NO path parameter — the route is flat.
///
/// Per ADR-019 + `PATTERN_MATCHING_POLICY.md §P2`, the DTO has 3 required
/// top-level strings (`tableName`, `codigo`, `descricao`) and no nested
/// required sub-DTOs, so the canonical **P2 if-case manual** path is used.
///
/// PII-safety (CRITICAL): `justificativa` is an optional free-narrative
/// field that may carry PII-dense rationale (e.g., mentioning a child's
/// condition or diagnosis). [parseFromBody] failures NEVER echo
/// `justificativa`, `codigo`, or `descricao` content back to the caller —
/// the error only enumerates the missing / empty required field names.
/// See `test/intents/create_lookup_request_intent_test.dart` for the
/// pinned contract.
final class CreateLookupRequestIntent with Equatable {
  const CreateLookupRequestIntent({required this.request});

  final CreateLookupRequestRequest request;

  @override
  List<Object?> get props => [request];

  /// Parses a decoded JSON body into an intent.
  ///
  /// Enforces the 3 required fields (`tableName`, `codigo`, `descricao`)
  /// as non-empty strings. `justificativa` is optional and carried
  /// verbatim via `_asString`. Missing required fields produce a [Failure]
  /// whose message enumerates the field names WITHOUT echoing any raw
  /// value.
  static Result<CreateLookupRequestIntent> parseFromBody(
    Map<String, dynamic> body,
  ) {
    final tableNameRaw = body['tableName'];
    final codigoRaw = body['codigo'];
    final descricaoRaw = body['descricao'];

    final tableName = tableNameRaw is String && tableNameRaw.isNotEmpty
        ? tableNameRaw
        : null;
    final codigo = codigoRaw is String && codigoRaw.isNotEmpty
        ? codigoRaw
        : null;
    final descricao = descricaoRaw is String && descricaoRaw.isNotEmpty
        ? descricaoRaw
        : null;

    final missing = <String>[];
    if (tableName == null) missing.add('tableName');
    if (codigo == null) missing.add('codigo');
    if (descricao == null) missing.add('descricao');

    if (missing.isEmpty) {
      final request = CreateLookupRequestRequest(
        tableName: tableName!,
        codigo: codigo!,
        descricao: descricao!,
        justificativa: _asString(body['justificativa']),
      );
      return Success(CreateLookupRequestIntent(request: request));
    }

    return Failure(
      _CreateLookupRequestParseError(
        'Invalid create-lookup-request body: missing or empty '
        '[${missing.join(', ')}]',
      ),
    );
  }

  static String? _asString(Object? raw) => raw is String ? raw : null;
}

/// Internal parse error for [CreateLookupRequestIntent.parseFromBody].
///
/// Deliberately avoids carrying any field value (`justificativa`,
/// `codigo`, `descricao`) so the error cannot be weaponized to leak
/// governance-request narrative content via logs or error responses.
///
/// Note: not `const` because the message is built dynamically from the
/// list of missing required fields.
final class _CreateLookupRequestParseError with Equatable implements Exception {
  _CreateLookupRequestParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}
