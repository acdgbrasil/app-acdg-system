import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '_shared/remote_base.dart';

/// Lookup remote — domain tables (`/api/v1/dominios/...`) and governance.
///
/// Eight methods. Backend uses Portuguese segment `dominios` (matches
/// Swift `LookupController.swift`). Note: `getLookupsBatch` has no
/// dedicated endpoint — we fan-out N parallel `GET /api/v1/dominios/{name}`
/// calls and assemble the result client-side (same approach as the web
/// BFF). 24x admin/governance endpoints synthesize a
/// `StandardResponse<void>` on 204 since the backend returns no body.
class LookupRemote extends RemoteBase implements LookupContract {
  LookupRemote({required super.dio});

  // ── Item queries ──────────────────────────────────────────────────────

  @override
  Future<Result<StandardResponse<List<LookupItemResponse>>>> getLookupTable(
    String tableName,
  ) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/v1/dominios/$tableName',
        options: RemoteBase.passthroughStatus,
      );
      if (response.statusCode == 200) {
        final data = response.data!['data'] as List<dynamic>;
        return Success<StandardResponse<List<LookupItemResponse>>>(
          wrapResponse(
            data
                .cast<Map<String, dynamic>>()
                .map(LookupItemResponse.fromJson)
                .toList(),
          ),
        );
      }
      return backendFailure(response, 'Lookup table $tableName not found');
    } catch (e, stackTrace) {
      return Failure<StandardResponse<List<LookupItemResponse>>>(
        e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Result<StandardResponse<LookupsBatchResponse>>> getLookupsBatch(
    List<String> tables,
  ) async {
    // REGRA #2 note: there is no backend batch endpoint. We fan-out one
    // `getLookupTable` per requested table and aggregate the results.
    // Any per-table failure short-circuits to `Failure`.
    try {
      final results = await Future.wait(tables.map(getLookupTable));
      final aggregated = <String, List<LookupItemResponse>>{};
      for (var i = 0; i < tables.length; i++) {
        final r = results[i];
        switch (r) {
          case Success(:final value):
            aggregated[tables[i]] = value.data;
          case Failure(:final error, :final stackTrace):
            return Failure<StandardResponse<LookupsBatchResponse>>(
              error,
              stackTrace: stackTrace,
            );
        }
      }
      return Success<StandardResponse<LookupsBatchResponse>>(
        wrapResponse(LookupsBatchResponse(tables: aggregated)),
      );
    } catch (e, stackTrace) {
      return Failure<StandardResponse<LookupsBatchResponse>>(
        e,
        stackTrace: stackTrace,
      );
    }
  }

  // ── Item admin ────────────────────────────────────────────────────────

  @override
  Future<Result<StandardIdResponse>> createLookupItem(
    String tableName,
    CreateLookupItemRequest request,
  ) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/v1/dominios/$tableName',
        data: request.toJson(),
        options: RemoteBase.passthroughStatus,
      );
      final code = response.statusCode;
      if (code == 201 || code == 200) {
        return Success<StandardIdResponse>(extractIdResponse(response.data!));
      }
      return backendFailure(response, 'Failed to create lookup item');
    } catch (e, stackTrace) {
      return Failure<StandardIdResponse>(e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<StandardResponse<void>>> updateLookupItem(
    String tableName,
    String itemId,
    UpdateLookupItemRequest request,
  ) async {
    try {
      final response = await dio.put<dynamic>(
        '/api/v1/dominios/$tableName/$itemId',
        data: request.toJson(),
        options: RemoteBase.passthroughStatus,
      );
      final code = response.statusCode;
      if (code == 204 || code == 200) {
        return Success<StandardResponse<void>>(wrapVoid());
      }
      return backendFailure(response, 'Failed to update lookup item');
    } catch (e, stackTrace) {
      return Failure<StandardResponse<void>>(e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<StandardResponse<void>>> toggleLookupItem(
    String tableName,
    String itemId,
    ToggleLookupItemRequest request,
  ) async {
    try {
      final response = await dio.patch<dynamic>(
        '/api/v1/dominios/$tableName/$itemId/toggle',
        data: request.toJson(),
        options: RemoteBase.passthroughStatus,
      );
      final code = response.statusCode;
      if (code == 204 || code == 200) {
        return Success<StandardResponse<void>>(wrapVoid());
      }
      return backendFailure(response, 'Failed to toggle lookup item');
    } catch (e, stackTrace) {
      return Failure<StandardResponse<void>>(e, stackTrace: stackTrace);
    }
  }

  // ── Governance requests ───────────────────────────────────────────────

  @override
  Future<Result<StandardResponse<List<LookupRequestResponse>>>>
  getLookupRequests() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/v1/dominios/requests',
        options: RemoteBase.passthroughStatus,
      );
      if (response.statusCode == 200) {
        final data = response.data!['data'] as List<dynamic>;
        return Success<StandardResponse<List<LookupRequestResponse>>>(
          wrapResponse(
            data
                .cast<Map<String, dynamic>>()
                .map(LookupRequestResponse.fromJson)
                .toList(),
          ),
        );
      }
      return backendFailure(response, 'Failed to get lookup requests');
    } catch (e, stackTrace) {
      return Failure<StandardResponse<List<LookupRequestResponse>>>(
        e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Result<StandardIdResponse>> createLookupRequest(
    CreateLookupRequestRequest request,
  ) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/v1/dominios/requests',
        data: request.toJson(),
        options: RemoteBase.passthroughStatus,
      );
      final code = response.statusCode;
      if (code == 201 || code == 200) {
        return Success<StandardIdResponse>(extractIdResponse(response.data!));
      }
      return backendFailure(response, 'Failed to create lookup request');
    } catch (e, stackTrace) {
      return Failure<StandardIdResponse>(e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<StandardResponse<void>>> approveLookupRequest(
    String requestId,
  ) => _governanceTransition(
    requestId,
    'approve',
    'Failed to approve lookup request',
  );

  @override
  Future<Result<StandardResponse<void>>> rejectLookupRequest(
    String requestId,
  ) => _governanceTransition(
    requestId,
    'reject',
    'Failed to reject lookup request',
  );

  Future<Result<StandardResponse<void>>> _governanceTransition(
    String requestId,
    String slug,
    String fallbackMessage,
  ) async {
    try {
      final response = await dio.put<dynamic>(
        '/api/v1/dominios/requests/$requestId/$slug',
        options: RemoteBase.passthroughStatus,
      );
      final code = response.statusCode;
      if (code == 204 || code == 200) {
        return Success<StandardResponse<void>>(wrapVoid());
      }
      return backendFailure(response, fallbackMessage);
    } catch (e, stackTrace) {
      return Failure<StandardResponse<void>>(e, stackTrace: stackTrace);
    }
  }
}
