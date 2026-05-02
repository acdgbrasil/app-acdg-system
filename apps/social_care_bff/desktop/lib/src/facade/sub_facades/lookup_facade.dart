import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../composition/builders/lookup_use_cases.dart';

/// Lookup sub-facade — 10 thin pass-through methods over the Lookup
/// use cases (A18b-v2).
///
/// Backed by [LookupUseCases] — a data class grouping the 10 use cases
/// (D02).
class LookupFacade {
  LookupFacade.internal({required LookupUseCases useCases})
    : _useCases = useCases;

  final LookupUseCases _useCases;

  // ── Tables ──────────────────────────────────────────────────────────

  Future<Result<List<LookupItemResponse>>> getLookupTable(String tableName) =>
      _useCases.getLookupTable(tableName);

  Future<Result<Map<String, List<LookupItemResponse>>>> getLookupsBatch(
    List<String> tables,
  ) => _useCases.getLookupsBatch(tables);

  // ── Items ───────────────────────────────────────────────────────────

  Future<Result<StandardIdResponse>> createLookupItem(
    String tableName,
    CreateLookupItemRequest req,
  ) => _useCases.createLookupItem(tableName, req);

  Future<Result<void>> updateLookupItem(
    String tableName,
    String itemId,
    UpdateLookupItemRequest req,
  ) => _useCases.updateLookupItem(tableName, itemId, req);

  Future<Result<void>> toggleLookupItem(
    String tableName,
    String itemId,
    ToggleLookupItemRequest req,
  ) => _useCases.toggleLookupItem(tableName, itemId, req);

  // ── Requests (governance) ───────────────────────────────────────────

  Future<Result<StandardIdResponse>> createLookupRequest(
    CreateLookupRequestRequest req,
  ) => _useCases.createLookupRequest(req);

  Future<Result<List<LookupRequestResponse>>> listLookupRequests({
    String? status,
    String? tableName,
    int? limit,
  }) => _useCases.listLookupRequests(
    status: status,
    tableName: tableName,
    limit: limit,
  );

  Future<Result<LookupRequestResponse?>> findLookupRequestById(
    String requestId,
  ) => _useCases.findLookupRequestById(requestId);

  Future<Result<void>> approveLookupRequest(String requestId) =>
      _useCases.approveLookupRequest(requestId);

  Future<Result<void>> rejectLookupRequest(String requestId) =>
      _useCases.rejectLookupRequest(requestId);
}
