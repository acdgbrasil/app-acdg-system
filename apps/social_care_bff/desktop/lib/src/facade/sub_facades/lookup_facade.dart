import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../use_cases/lookup/approve_lookup_request_use_case.dart';
import '../../use_cases/lookup/create_lookup_item_use_case.dart';
import '../../use_cases/lookup/create_lookup_request_use_case.dart';
import '../../use_cases/lookup/find_lookup_request_by_id_use_case.dart';
import '../../use_cases/lookup/get_lookup_table_use_case.dart';
import '../../use_cases/lookup/get_lookups_batch_use_case.dart';
import '../../use_cases/lookup/list_lookup_requests_use_case.dart';
import '../../use_cases/lookup/reject_lookup_request_use_case.dart';
import '../../use_cases/lookup/toggle_lookup_item_use_case.dart';
import '../../use_cases/lookup/update_lookup_item_use_case.dart';

/// Lookup sub-facade — 10 thin pass-through methods over the Lookup
/// use cases (A18b-v2).
class LookupFacade {
  LookupFacade.internal({
    required GetLookupTableUseCase getLookupTable,
    required GetLookupsBatchUseCase getLookupsBatch,
    required CreateLookupItemUseCase createLookupItem,
    required UpdateLookupItemUseCase updateLookupItem,
    required ToggleLookupItemUseCase toggleLookupItem,
    required CreateLookupRequestUseCase createLookupRequest,
    required ListLookupRequestsUseCase listLookupRequests,
    required FindLookupRequestByIdUseCase findLookupRequestById,
    required ApproveLookupRequestUseCase approveLookupRequest,
    required RejectLookupRequestUseCase rejectLookupRequest,
  }) : _getLookupTable = getLookupTable,
       _getLookupsBatch = getLookupsBatch,
       _createLookupItem = createLookupItem,
       _updateLookupItem = updateLookupItem,
       _toggleLookupItem = toggleLookupItem,
       _createLookupRequest = createLookupRequest,
       _listLookupRequests = listLookupRequests,
       _findLookupRequestById = findLookupRequestById,
       _approveLookupRequest = approveLookupRequest,
       _rejectLookupRequest = rejectLookupRequest;

  final GetLookupTableUseCase _getLookupTable;
  final GetLookupsBatchUseCase _getLookupsBatch;
  final CreateLookupItemUseCase _createLookupItem;
  final UpdateLookupItemUseCase _updateLookupItem;
  final ToggleLookupItemUseCase _toggleLookupItem;
  final CreateLookupRequestUseCase _createLookupRequest;
  final ListLookupRequestsUseCase _listLookupRequests;
  final FindLookupRequestByIdUseCase _findLookupRequestById;
  final ApproveLookupRequestUseCase _approveLookupRequest;
  final RejectLookupRequestUseCase _rejectLookupRequest;

  // ── Tables ──────────────────────────────────────────────────────────

  Future<Result<List<LookupItemResponse>>> getLookupTable(String tableName) =>
      _getLookupTable(tableName);

  Future<Result<Map<String, List<LookupItemResponse>>>> getLookupsBatch(
    List<String> tables,
  ) => _getLookupsBatch(tables);

  // ── Items ───────────────────────────────────────────────────────────

  Future<Result<StandardIdResponse>> createLookupItem(
    String tableName,
    CreateLookupItemRequest req,
  ) => _createLookupItem(tableName, req);

  Future<Result<void>> updateLookupItem(
    String tableName,
    String itemId,
    UpdateLookupItemRequest req,
  ) => _updateLookupItem(tableName, itemId, req);

  Future<Result<void>> toggleLookupItem(
    String tableName,
    String itemId,
    ToggleLookupItemRequest req,
  ) => _toggleLookupItem(tableName, itemId, req);

  // ── Requests (governance) ───────────────────────────────────────────

  Future<Result<StandardIdResponse>> createLookupRequest(
    CreateLookupRequestRequest req,
  ) => _createLookupRequest(req);

  Future<Result<List<LookupRequestResponse>>> listLookupRequests({
    String? status,
    String? tableName,
    int? limit,
  }) => _listLookupRequests(status: status, tableName: tableName, limit: limit);

  Future<Result<LookupRequestResponse?>> findLookupRequestById(
    String requestId,
  ) => _findLookupRequestById(requestId);

  Future<Result<void>> approveLookupRequest(String requestId) =>
      _approveLookupRequest(requestId);

  Future<Result<void>> rejectLookupRequest(String requestId) =>
      _rejectLookupRequest(requestId);
}
