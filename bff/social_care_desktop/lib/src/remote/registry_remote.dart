import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '_shared/remote_base.dart';

/// Registry remote — patients, family members, social identity, lifecycle.
///
/// Eleven methods, all under `/api/v1/patients[...]`. Lifecycle and
/// family-member transitions return `Future<Result<void>>` (the wire is
/// 204/200 on replay); creates return `StandardIdResponse`; reads
/// return either `PaginatedList` (list) or `StandardResponse<...>`
/// (single resource).
class RegistryRemote extends RemoteBase implements RegistryContract {
  RegistryRemote({required super.dio});

  // ── Patients ──────────────────────────────────────────────────────────

  @override
  Future<Result<PaginatedList<PatientSummaryResponse>>> fetchPatients({
    String? search,
    String? status,
    String? cursor,
    int? limit,
  }) async {
    try {
      final params = <String, dynamic>{
        'search': ?search,
        'status': ?status,
        'cursor': ?cursor,
        'limit': limit ?? 100,
      };
      final response = await dio.get<Map<String, dynamic>>(
        '/api/v1/patients',
        queryParameters: params,
        options: RemoteBase.passthroughStatus,
      );
      if (response.statusCode == 200) {
        final body = response.data!;
        final data = body['data'] as List<dynamic>;
        final meta = body['meta'] as Map<String, dynamic>;
        return Success<PaginatedList<PatientSummaryResponse>>(
          PaginatedList<PatientSummaryResponse>(
            data: data
                .cast<Map<String, dynamic>>()
                .map(PatientSummaryResponse.fromJson)
                .toList(),
            meta: PaginationMeta.fromJson(meta),
          ),
        );
      }
      return backendFailure(response, 'Failed to list patients');
    } catch (e, stackTrace) {
      return Failure<PaginatedList<PatientSummaryResponse>>(
        e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Result<StandardIdResponse>> registerPatient(
    RegisterPatientRequest request,
  ) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/v1/patients',
        data: request.toJson(),
        options: RemoteBase.passthroughStatus,
      );
      final code = response.statusCode;
      if (code == 201 || code == 200) {
        return Success<StandardIdResponse>(extractIdResponse(response.data!));
      }
      return backendFailure(response, 'Failed to register patient');
    } catch (e, stackTrace) {
      return Failure<StandardIdResponse>(e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<StandardResponse<PatientResponse>>> fetchPatient(
    String patientId,
  ) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/v1/patients/$patientId',
        options: RemoteBase.passthroughStatus,
      );
      if (response.statusCode == 200) {
        final data = response.data!['data'] as Map<String, dynamic>;
        return Success<StandardResponse<PatientResponse>>(
          wrapResponse(PatientResponse.fromJson(data)),
        );
      }
      return backendFailure(response, 'Patient not found');
    } catch (e, stackTrace) {
      return Failure<StandardResponse<PatientResponse>>(
        e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Result<StandardResponse<PatientResponse>>> fetchPatientByPersonId(
    String personId,
  ) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/v1/patients/by-person/$personId',
        options: RemoteBase.passthroughStatus,
      );
      if (response.statusCode == 200) {
        final data = response.data!['data'] as Map<String, dynamic>;
        return Success<StandardResponse<PatientResponse>>(
          wrapResponse(PatientResponse.fromJson(data)),
        );
      }
      return backendFailure(response, 'Patient not found');
    } catch (e, stackTrace) {
      return Failure<StandardResponse<PatientResponse>>(
        e,
        stackTrace: stackTrace,
      );
    }
  }

  // ── Family Members ────────────────────────────────────────────────────

  @override
  Future<Result<void>> addFamilyMember(
    String patientId,
    AddFamilyMemberRequest request, {
    String? cpf,
  }) async {
    // REGRA #2 note: the optional `cpf` parameter is preserved on the
    // sub-contract for backwards compatibility but is intentionally NOT
    // forwarded on the wire — the legacy backend ignored it and the
    // tests assert this behavior. If the backend later starts using it,
    // RegistryContract must change first; we'll pass it as a header or
    // body field at that time.
    try {
      final response = await dio.post<dynamic>(
        '/api/v1/patients/$patientId/family-members',
        data: request.toJson(),
        options: RemoteBase.passthroughStatus,
      );
      final code = response.statusCode;
      if (code == 204 || code == 201 || code == 200) {
        return const Success<void>(null);
      }
      return backendFailure(response, 'Failed to add family member');
    } catch (e, stackTrace) {
      return Failure<void>(e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<void>> removeFamilyMember(
    String patientId,
    String memberId,
  ) async {
    try {
      final response = await dio.delete<dynamic>(
        '/api/v1/patients/$patientId/family-members/$memberId',
        options: RemoteBase.passthroughStatus,
      );
      final code = response.statusCode;
      if (code == 204 || code == 200) {
        return const Success<void>(null);
      }
      return backendFailure(response, 'Failed to remove family member');
    } catch (e, stackTrace) {
      return Failure<void>(e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<void>> assignPrimaryCaregiver(
    String patientId,
    AssignPrimaryCaregiverRequest request,
  ) async {
    try {
      final response = await dio.put<dynamic>(
        '/api/v1/patients/$patientId/primary-caregiver',
        data: request.toJson(),
        options: RemoteBase.passthroughStatus,
      );
      final code = response.statusCode;
      if (code == 204 || code == 200) {
        return const Success<void>(null);
      }
      return backendFailure(response, 'Failed to assign primary caregiver');
    } catch (e, stackTrace) {
      return Failure<void>(e, stackTrace: stackTrace);
    }
  }

  // ── Social Identity ───────────────────────────────────────────────────

  @override
  Future<Result<void>> updateSocialIdentity(
    String patientId,
    UpdateSocialIdentityRequest request,
  ) async {
    try {
      final response = await dio.put<dynamic>(
        '/api/v1/patients/$patientId/social-identity',
        data: request.toJson(),
        options: RemoteBase.passthroughStatus,
      );
      final code = response.statusCode;
      if (code == 204 || code == 200) {
        return const Success<void>(null);
      }
      return backendFailure(response, 'Failed to update social identity');
    } catch (e, stackTrace) {
      return Failure<void>(e, stackTrace: stackTrace);
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────

  Future<Result<void>> _postLifecycle(
    String patientId,
    String slug,
    Map<String, dynamic>? body,
    String fallbackMessage,
  ) async {
    try {
      final response = await dio.post<dynamic>(
        '/api/v1/patients/$patientId/$slug',
        data: body,
        options: RemoteBase.passthroughStatus,
      );
      final code = response.statusCode;
      if (code == 204 || code == 200) {
        return const Success<void>(null);
      }
      return backendFailure(response, fallbackMessage);
    } catch (e, stackTrace) {
      return Failure<void>(e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<void>> dischargePatient(
    String patientId,
    DischargePatientRequest request,
  ) => _postLifecycle(
    patientId,
    'discharge',
    request.toJson(),
    'Failed to discharge patient',
  );

  @override
  Future<Result<void>> readmitPatient(
    String patientId,
    ReadmitPatientRequest request,
  ) => _postLifecycle(
    patientId,
    'readmit',
    request.toJson(),
    'Failed to readmit patient',
  );

  @override
  Future<Result<void>> admitPatient(String patientId) =>
      _postLifecycle(patientId, 'admit', null, 'Failed to admit patient');

  @override
  Future<Result<void>> withdrawPatient(
    String patientId,
    WithdrawPatientRequest request,
  ) => _postLifecycle(
    patientId,
    'withdraw',
    request.toJson(),
    'Failed to withdraw patient',
  );
}
