import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/approve_lookup_request_intent.dart';
import '../observability/observability_context.dart';

/// Approves a pending governance request by delegating to
/// [LookupContract.approveLookupRequest].
///
/// Emits the canonical triad of breadcrumbs:
/// - `lookup.request.approve.received` on dispatch (carries `requestId`).
/// - `lookup.request.approve.completed` on success (no data).
/// - `lookup.request.approve.failed` on error (carries `errorCode`).
final class ApproveLookupRequestUseCase {
  const ApproveLookupRequestUseCase({required LookupContract lookup})
    : _lookup = lookup;

  final LookupContract _lookup;

  Future<Result<StandardResponse<void>>> execute(
    ApproveLookupRequestIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'lookup.request.approve.received',
      data: {'requestId': intent.requestId},
    );

    final result = await _lookup.approveLookupRequest(intent.requestId);

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb('lookup.request.approve.completed');
        return Success<StandardResponse<void>>(value);
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'lookup.request.approve.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
