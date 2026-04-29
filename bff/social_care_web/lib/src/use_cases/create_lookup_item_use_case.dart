import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/create_lookup_item_intent.dart';
import '../observability/observability_context.dart';

/// Creates a new lookup item by delegating to
/// [LookupContract.createLookupItem].
///
/// Emits the canonical triad of breadcrumbs:
/// - `lookup.item.create.received` on dispatch (carries `tableName` ONLY —
///   never `codigo` / `descricao`, which are domain content confined to
///   the upstream call path).
/// - `lookup.item.create.completed` on success (carries `itemId` — a
///   non-PII UUID-like id).
/// - `lookup.item.create.failed` on error (carries `errorCode`).
final class CreateLookupItemUseCase {
  const CreateLookupItemUseCase({required LookupContract lookup})
    : _lookup = lookup;

  final LookupContract _lookup;

  Future<Result<StandardIdResponse>> execute(
    CreateLookupItemIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'lookup.item.create.received',
      data: {'tableName': intent.tableName},
    );

    final result = await _lookup.createLookupItem(
      intent.tableName,
      intent.request,
    );

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb(
          'lookup.item.create.completed',
          data: {'itemId': value.data.id},
        );
        return Success<StandardIdResponse>(value);
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'lookup.item.create.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardIdResponse>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
