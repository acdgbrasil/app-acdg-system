import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/get_lookup_requests_intent.dart';
import '../observability/observability_context.dart';

/// Lists governance requests by delegating to
/// [LookupContract.getLookupRequests].
///
/// Emits the canonical triad of breadcrumbs:
/// - `lookup.request.list.received` on dispatch (no data — the intent is
///   empty).
/// - `lookup.request.list.completed` on success (carries `count`).
/// - `lookup.request.list.failed` on error (carries `errorCode`).
///
/// PII-safety: breadcrumbs NEVER echo `justificativa` / `codigo` /
/// `descricao` from seeded requests — only aggregate `count` surfaces.
final class GetLookupRequestsUseCase {
  const GetLookupRequestsUseCase({required LookupContract lookup})
    : _lookup = lookup;

  final LookupContract _lookup;

  Future<Result<StandardResponse<List<LookupRequestResponse>>>> execute(
    GetLookupRequestsIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb('lookup.request.list.received');

    final result = await _lookup.getLookupRequests();

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb(
          'lookup.request.list.completed',
          data: {'count': value.data.length},
        );
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'lookup.request.list.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
