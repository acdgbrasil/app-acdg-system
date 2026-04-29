import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/toggle_lookup_item_intent.dart';
import '../observability/observability_context.dart';

/// Toggles a lookup item's active flag by delegating to
/// [LookupContract.toggleLookupItem].
///
/// Emits the canonical triad of breadcrumbs:
/// - `lookup.item.toggle.received` on dispatch (carries `tableName`,
///   `itemId`, and `active` — all non-PII domain/UUID/bool values).
/// - `lookup.item.toggle.completed` on success (no data).
/// - `lookup.item.toggle.failed` on error (carries `errorCode`).
final class ToggleLookupItemUseCase {
  const ToggleLookupItemUseCase({required LookupContract lookup})
    : _lookup = lookup;

  final LookupContract _lookup;

  Future<Result<StandardResponse<void>>> execute(
    ToggleLookupItemIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'lookup.item.toggle.received',
      data: {
        'tableName': intent.tableName,
        'itemId': intent.itemId,
        'active': intent.request.active,
      },
    );

    final result = await _lookup.toggleLookupItem(
      intent.tableName,
      intent.itemId,
      intent.request,
    );

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb('lookup.item.toggle.completed');
        return Success<StandardResponse<void>>(value);
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'lookup.item.toggle.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
