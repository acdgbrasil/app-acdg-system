import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/create_lookup_request_intent.dart';
import '../observability/observability_context.dart';

/// Creates a new governance request by delegating to
/// [LookupContract.createLookupRequest].
///
/// Emits the canonical triad of breadcrumbs:
/// - `lookup.request.create.received` on dispatch (carries `tableName`
///   **ONLY** — never `codigo`, `descricao`, or `justificativa`, which may
///   carry PII-dense narrative rationale).
/// - `lookup.request.create.completed` on success (carries `requestId` —
///   a non-PII UUID-like id).
/// - `lookup.request.create.failed` on error (carries `errorCode`).
///
/// PII-safety (CRITICAL): `.received` is the PII firewall — the intent
/// carries 4 fields (3 required + optional narrative) but only `tableName`
/// (domain metadata) surfaces in observability runtime. Raw user content
/// goes to the BFF audit trail, not to logs / breadcrumbs.
final class CreateLookupRequestUseCase {
  const CreateLookupRequestUseCase({required LookupContract lookup})
    : _lookup = lookup;

  final LookupContract _lookup;

  Future<Result<StandardIdResponse>> execute(
    CreateLookupRequestIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'lookup.request.create.received',
      data: {'tableName': intent.request.tableName},
    );

    final result = await _lookup.createLookupRequest(intent.request);

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb(
          'lookup.request.create.completed',
          data: {'requestId': value.data.id},
        );
        return Success<StandardIdResponse>(value);
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'lookup.request.create.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardIdResponse>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
