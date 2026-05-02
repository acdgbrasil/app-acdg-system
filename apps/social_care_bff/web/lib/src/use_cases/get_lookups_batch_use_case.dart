import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/get_lookups_batch_intent.dart';
import '../observability/observability_context.dart';

/// Fetches multiple lookup tables in a single round trip by delegating to
/// [LookupContract.getLookupsBatch].
///
/// Emits the canonical triad of breadcrumbs (mirrors
/// [GetLookupTableUseCase], scoped under the `lookup.batch.get.*`
/// namespace):
/// - `lookup.batch.get.received` on dispatch (carries `tableCount`)
/// - `lookup.batch.get.completed` on success (carries `totalItems`)
/// - `lookup.batch.get.failed` on error (carries `errorCode`)
final class GetLookupsBatchUseCase {
  const GetLookupsBatchUseCase({required LookupContract lookup})
    : _lookup = lookup;

  final LookupContract _lookup;

  Future<Result<StandardResponse<LookupsBatchResponse>>> execute(
    GetLookupsBatchIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'lookup.batch.get.received',
      data: {'tableCount': intent.tables.length},
    );

    final result = await _lookup.getLookupsBatch(intent.tables);

    return switch (result) {
      Success(:final value) => () {
        final totalItems = value.data.tables.values.fold<int>(
          0,
          (sum, list) => sum + list.length,
        );
        obs.breadcrumb(
          'lookup.batch.get.completed',
          data: {'totalItems': totalItems},
        );
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'lookup.batch.get.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
