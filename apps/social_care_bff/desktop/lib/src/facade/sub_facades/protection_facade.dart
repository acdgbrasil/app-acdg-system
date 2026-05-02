import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../use_cases/protection/create_referral_use_case.dart';
import '../../use_cases/protection/fetch_placement_history_use_case.dart';
import '../../use_cases/protection/list_referrals_use_case.dart';
import '../../use_cases/protection/list_violation_reports_use_case.dart';
import '../../use_cases/protection/report_violation_use_case.dart';
import '../../use_cases/protection/update_placement_history_use_case.dart';

/// Protection sub-facade — 6 thin pass-through methods over the
/// Protection use cases (A18b-v2).
class ProtectionFacade {
  ProtectionFacade.internal({
    required CreateReferralUseCase createReferral,
    required ListReferralsUseCase listReferrals,
    required ReportViolationUseCase reportViolation,
    required ListViolationReportsUseCase listViolationReports,
    required FetchPlacementHistoryUseCase fetchPlacementHistory,
    required UpdatePlacementHistoryUseCase updatePlacementHistory,
  }) : _createReferral = createReferral,
       _listReferrals = listReferrals,
       _reportViolation = reportViolation,
       _listViolationReports = listViolationReports,
       _fetchPlacementHistory = fetchPlacementHistory,
       _updatePlacementHistory = updatePlacementHistory;

  final CreateReferralUseCase _createReferral;
  final ListReferralsUseCase _listReferrals;
  final ReportViolationUseCase _reportViolation;
  final ListViolationReportsUseCase _listViolationReports;
  final FetchPlacementHistoryUseCase _fetchPlacementHistory;
  final UpdatePlacementHistoryUseCase _updatePlacementHistory;

  Future<Result<StandardIdResponse>> createReferral(
    String patientId,
    CreateReferralRequest req,
  ) => _createReferral(patientId, req);

  Future<Result<List<ReferralResponse>>> listReferrals(String patientId) =>
      _listReferrals(patientId);

  Future<Result<StandardIdResponse>> reportViolation(
    String patientId,
    ReportRightsViolationRequest req,
  ) => _reportViolation(patientId, req);

  Future<Result<List<ViolationReportResponse>>> listViolationReports(
    String patientId,
  ) => _listViolationReports(patientId);

  Future<Result<PlacementHistoryResponse?>> fetchPlacementHistory(
    String patientId,
  ) => _fetchPlacementHistory(patientId);

  Future<Result<void>> updatePlacementHistory(
    String patientId,
    UpdatePlacementHistoryRequest req,
  ) => _updatePlacementHistory(patientId, req);
}
