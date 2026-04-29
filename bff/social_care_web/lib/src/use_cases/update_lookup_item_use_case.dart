import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/update_lookup_item_intent.dart';
import '../observability/observability_context.dart';

/// Updates a lookup item by delegating to
/// [LookupContract.updateLookupItem].
///
/// Emits the canonical triad of breadcrumbs:
/// - `lookup.item.update.received` on dispatch (carries `tableName` and
///   `itemId` — both non-PII domain/UUID identifiers).
/// - `lookup.item.update.completed` on success (no data).
/// - `lookup.item.update.failed` on error (carries `errorCode`).
///
/// PII-safety: breadcrumbs NEVER echo `codigo` / `descricao` — these are
/// domain content confined to the upstream call path.
final class UpdateLookupItemUseCase {
  const UpdateLookupItemUseCase({required LookupContract lookup})
    : _lookup = lookup;

  final LookupContract _lookup;

  Future<Result<StandardResponse<void>>> execute(
    UpdateLookupItemIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'lookup.item.update.received',
      data: {'tableName': intent.tableName, 'itemId': intent.itemId},
    );

    final result = await _lookup.updateLookupItem(
      intent.tableName,
      intent.itemId,
      intent.request,
    );

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb('lookup.item.update.completed');
        return Success<StandardResponse<void>>(value);
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'lookup.item.update.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
