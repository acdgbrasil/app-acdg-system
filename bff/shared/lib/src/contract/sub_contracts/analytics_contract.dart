import 'package:core_contracts/core_contracts.dart';

import '../dto/responses/analytics/axis_metadata_response.dart';
import '../dto/responses/analytics/indicator_response.dart';
import '../dto/shared/standard_response.dart';

/// Analytics contract — anonymized indicators from Analysis BI.
///
/// Represents the BFF's interaction with the Analysis BI service.
/// All data is anonymized with K-anonymity (K=5) enforcement.
/// PII is never exposed through this contract.
abstract interface class AnalyticsContract {
  /// Retrieves anonymized indicators for a given [axis].
  ///
  /// Available axes: demographics, epidemiological, socioeconomic,
  /// protection, care.
  Future<Result<StandardResponse<IndicatorResponse>>> getIndicators(
    String axis, {
    String? period,
  });

  /// Lists available indicator axes with their metadata.
  Future<Result<StandardResponse<List<AxisMetadataResponse>>>>
  getAxesMetadata();
}
