import 'package:core_contracts/core_contracts.dart';

import '../dto/requests/protection/create_referral_request.dart';
import '../dto/requests/protection/report_rights_violation_request.dart';
import '../dto/requests/protection/update_placement_history_request.dart';
import '../dto/shared/standard_response.dart';

/// Protection contract — referrals, violations, and placement history.
abstract interface class ProtectionContract {
  /// Updates the institutional placement history.
  Future<Result<void>> updatePlacementHistory(
    String patientId,
    UpdatePlacementHistoryRequest request,
  );

  /// Reports a new rights violation.
  /// Returns [StandardIdResponse] with the generated violation report ID.
  Future<Result<StandardIdResponse>> reportViolation(
    String patientId,
    ReportRightsViolationRequest request,
  );

  /// Creates a new referral.
  /// Returns [StandardIdResponse] with the generated referral ID.
  Future<Result<StandardIdResponse>> createReferral(
    String patientId,
    CreateReferralRequest request,
  );
}
