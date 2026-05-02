import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/get_lookup_table_intent.dart';
import '../observability/observability_context.dart';

/// Fetches a single lookup table by delegating to
/// [LookupContract.getLookupTable].
///
/// Emits the canonical triad of breadcrumbs:
/// - `lookup.table.get.received` on dispatch (carries `tableName`)
/// - `lookup.table.get.completed` on success (carries `count`)
/// - `lookup.table.get.failed` on error (carries `errorCode`)
final class GetLookupTableUseCase {
  const GetLookupTableUseCase({required LookupContract lookup})
    : _lookup = lookup;

  final LookupContract _lookup;

  Future<Result<StandardResponse<List<LookupItemResponse>>>> execute(
    GetLookupTableIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'lookup.table.get.received',
      data: {'tableName': intent.tableName},
    );

    final result = await _lookup.getLookupTable(intent.tableName);

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb(
          'lookup.table.get.completed',
          data: {'count': value.data.length},
        );
        return result;
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'lookup.table.get.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return result;
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}
