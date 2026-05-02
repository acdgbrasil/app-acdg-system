import 'package:core_contracts/core_contracts.dart';

import '../contract/dto/responses/analytics/axis_metadata_response.dart';
import '../contract/dto/responses/analytics/indicator_response.dart';
import '../contract/dto/shared/standard_response.dart';
import '../contract/sub_contracts/analytics_contract.dart';

/// In-memory fake for [AnalyticsContract] — used in tests and local
/// simulation. Returns empty datasets by default.
class FakeAnalyticsBff implements AnalyticsContract {
  StandardResponse<T> _wrap<T>(T data) => StandardResponse(
    data: data,
    meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
  );

  @override
  Future<Result<StandardResponse<IndicatorResponse>>> getIndicators(
    String axis, {
    String? period,
  }) async {
    return Success(_wrap(IndicatorResponse(axis: axis, rows: const [])));
  }

  @override
  Future<Result<StandardResponse<List<AxisMetadataResponse>>>>
  getAxesMetadata() async {
    return Success(_wrap(const <AxisMetadataResponse>[]));
  }
}
