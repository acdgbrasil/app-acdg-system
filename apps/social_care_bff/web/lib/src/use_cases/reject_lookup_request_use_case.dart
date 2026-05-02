import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/reject_lookup_request_intent.dart';
import '../observability/observability_context.dart';

/// Rejects a pending governance request by delegating to
/// [LookupContract.rejectLookupRequest].
///
/// Emits the canonical triad of breadcrumbs:
/// - `lookup.request.reject.received` on dispatch (carries `requestId`).
/// - `lookup.request.reject.completed` on success (no data).
/// - `lookup.request.reject.failed` on error (carries `errorCode`).
final class RejectLookupRequestUseCase {
  const RejectLookupRequestUseCase({required LookupContract lookup})
    : _lookup = lookup;

  final LookupContract _lookup;

  Future<Result<StandardResponse<void>>> execute(
    RejectLookupRequestIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'lookup.request.reject.received',
      data: {'requestId': intent.requestId},
    );

    final result = await _lookup.rejectLookupRequest(intent.requestId);

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb('lookup.request.reject.completed');
        return Success<StandardResponse<void>>(value);
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'lookup.request.reject.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
