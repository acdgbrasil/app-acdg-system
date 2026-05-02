import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../composition/builders/protection_use_cases.dart';

/// Protection sub-facade — 6 thin pass-through methods over the
/// Protection use cases (A18b-v2).
///
/// Backed by [ProtectionUseCases] — a data class grouping the 6 use
/// cases (D02).
class ProtectionFacade {
  ProtectionFacade.internal({required ProtectionUseCases useCases})
    : _useCases = useCases;

  final ProtectionUseCases _useCases;

  Future<Result<StandardIdResponse>> createReferral(
    String patientId,
    CreateReferralRequest req,
  ) => _useCases.createReferral(patientId, req);

  Future<Result<List<ReferralResponse>>> listReferrals(String patientId) =>
      _useCases.listReferrals(patientId);

  Future<Result<StandardIdResponse>> reportViolation(
    String patientId,
    ReportRightsViolationRequest req,
  ) => _useCases.reportViolation(patientId, req);

  Future<Result<List<ViolationReportResponse>>> listViolationReports(
    String patientId,
  ) => _useCases.listViolationReports(patientId);

  Future<Result<PlacementHistoryResponse?>> fetchPlacementHistory(
    String patientId,
  ) => _useCases.fetchPlacementHistory(patientId);

  Future<Result<void>> updatePlacementHistory(
    String patientId,
    UpdatePlacementHistoryRequest req,
  ) => _useCases.updatePlacementHistory(patientId, req);
}
