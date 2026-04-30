import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '_shared/remote_base.dart';

/// Protection remote — placement history, violation reports, referrals.
class ProtectionRemote extends RemoteBase implements ProtectionContract {
  ProtectionRemote({required super.dio});

  @override
  Future<Result<void>> updatePlacementHistory(
    String patientId,
    UpdatePlacementHistoryRequest request,
  ) async {
    try {
      final response = await dio.put<dynamic>(
        '/api/v1/patients/$patientId/placement-history',
        data: request.toJson(),
        options: RemoteBase.passthroughStatus,
      );
      final code = response.statusCode;
      if (code == 204 || code == 200) {
        return const Success<void>(null);
      }
      return backendFailure(response, 'Failed to update placement history');
    } catch (e, stackTrace) {
      return Failure<void>(e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<StandardIdResponse>> reportViolation(
    String patientId,
    ReportRightsViolationRequest request,
  ) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/v1/patients/$patientId/violation-reports',
        data: request.toJson(),
        options: RemoteBase.passthroughStatus,
      );
      final code = response.statusCode;
      if (code == 201 || code == 200) {
        return Success<StandardIdResponse>(extractIdResponse(response.data!));
      }
      return backendFailure(response, 'Failed to report violation');
    } catch (e, stackTrace) {
      return Failure<StandardIdResponse>(e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<StandardIdResponse>> createReferral(
    String patientId,
    CreateReferralRequest request,
  ) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/v1/patients/$patientId/referrals',
        data: request.toJson(),
        options: RemoteBase.passthroughStatus,
      );
      final code = response.statusCode;
      if (code == 201 || code == 200) {
        return Success<StandardIdResponse>(extractIdResponse(response.data!));
      }
      return backendFailure(response, 'Failed to create referral');
    } catch (e, stackTrace) {
      return Failure<StandardIdResponse>(e, stackTrace: stackTrace);
    }
  }
}
