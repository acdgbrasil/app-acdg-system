import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '_shared/remote_base.dart';

/// Assessment remote — 7 fichas under `/api/v1/patients/{patientId}/`.
///
/// Every endpoint follows the same shape: `PUT <slug>` with a typed
/// request body, returning `Result<void>`. The shared `_putFicha`
/// helper keeps each public method to a single line so adding/removing
/// a ficha is a one-line change.
class AssessmentRemote extends RemoteBase implements AssessmentContract {
  AssessmentRemote({required super.dio});

  Future<Result<void>> _putFicha(
    String patientId,
    String slug,
    Map<String, dynamic> body,
    String fallbackMessage,
  ) async {
    try {
      final response = await dio.put<dynamic>(
        '/api/v1/patients/$patientId/$slug',
        data: body,
        options: RemoteBase.passthroughStatus,
      );
      final code = response.statusCode;
      if (code == 204 || code == 200) {
        return const Success<void>(null);
      }
      return backendFailure(response, fallbackMessage);
    } on Object catch (e, stackTrace) {
      return Failure<void>(e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<void>> updateHousingCondition(
    String patientId,
    UpdateHousingConditionRequest request,
  ) => _putFicha(
    patientId,
    'housing-condition',
    request.toJson(),
    'Failed to update housing condition',
  );

  @override
  Future<Result<void>> updateSocioEconomicSituation(
    String patientId,
    UpdateSocioEconomicSituationRequest request,
  ) => _putFicha(
    patientId,
    'socioeconomic-situation',
    request.toJson(),
    'Failed to update socio-economic situation',
  );

  @override
  Future<Result<void>> updateWorkAndIncome(
    String patientId,
    UpdateWorkAndIncomeRequest request,
  ) => _putFicha(
    patientId,
    'work-and-income',
    request.toJson(),
    'Failed to update work and income',
  );

  @override
  Future<Result<void>> updateEducationalStatus(
    String patientId,
    UpdateEducationalStatusRequest request,
  ) => _putFicha(
    patientId,
    'educational-status',
    request.toJson(),
    'Failed to update educational status',
  );

  @override
  Future<Result<void>> updateHealthStatus(
    String patientId,
    UpdateHealthStatusRequest request,
  ) => _putFicha(
    patientId,
    'health-status',
    request.toJson(),
    'Failed to update health status',
  );

  @override
  Future<Result<void>> updateCommunitySupportNetwork(
    String patientId,
    UpdateCommunitySupportNetworkRequest request,
  ) => _putFicha(
    patientId,
    'community-support-network',
    request.toJson(),
    'Failed to update community support network',
  );

  @override
  Future<Result<void>> updateSocialHealthSummary(
    String patientId,
    UpdateSocialHealthSummaryRequest request,
  ) => _putFicha(
    patientId,
    'social-health-summary',
    request.toJson(),
    'Failed to update social health summary',
  );
}
