import 'package:core_contracts/core_contracts.dart';

import '../contract/dto/requests/governance/create_lookup_item_request.dart';
import '../contract/dto/requests/governance/create_lookup_request_request.dart';
import '../contract/dto/requests/governance/toggle_lookup_item_request.dart';
import '../contract/dto/requests/governance/update_lookup_item_request.dart';
import '../contract/dto/responses/governance/lookup_item_response.dart';
import '../contract/dto/responses/governance/lookup_request_response.dart';
import '../contract/dto/responses/governance/lookups_batch_response.dart';
import '../contract/dto/shared/standard_response.dart';
import '../contract/sub_contracts/lookup_contract.dart';
import 'stores/in_memory_lookup_store.dart';

/// In-memory fake for [LookupContract].
///
/// State is held in an [InMemoryLookupStore] — a public collaborator the
/// tests can inspect or pre-seed via `fake.store.tables[...]`.
class FakeLookupBff implements LookupContract {
  FakeLookupBff({InMemoryLookupStore? store})
      : store = store ?? InMemoryLookupStore();

  final InMemoryLookupStore store;

  String _nextId() => DateTime.now().microsecondsSinceEpoch.toString();

  StandardResponse<T> _wrap<T>(T data) => StandardResponse(
    data: data,
    meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
  );

  StandardIdResponse _wrapId(String id) => _wrap(IdData(id: id));

  // ── Item queries ────────────────────────────────────────────────────────

  @override
  Future<Result<StandardResponse<List<LookupItemResponse>>>> getLookupTable(
    String tableName,
  ) async {
    return Success(_wrap(store.getTable(tableName)));
  }

  @override
  Future<Result<StandardResponse<LookupsBatchResponse>>> getLookupsBatch(
    List<String> tables,
  ) async {
    final result = <String, List<LookupItemResponse>>{};
    for (final table in tables) {
      result[table] = store.getTable(table);
    }
    return Success(_wrap(LookupsBatchResponse(tables: result)));
  }

  // ── Item admin ──────────────────────────────────────────────────────────

  @override
  Future<Result<StandardIdResponse>> createLookupItem(
    String tableName,
    CreateLookupItemRequest request,
  ) async {
    final id = _nextId();
    store.addItem(
      tableName,
      LookupItemResponse(
        id: id,
        codigo: request.codigo,
        descricao: request.descricao,
      ),
    );
    return Success(_wrapId(id));
  }

  @override
  Future<Result<StandardResponse<void>>> updateLookupItem(
    String tableName,
    String itemId,
    UpdateLookupItemRequest request,
  ) async {
    final list = store.tables[tableName];
    if (list == null) return Success(_wrap(null));
    final index = list.indexWhere((item) => item.id == itemId);
    if (index == -1) return Success(_wrap(null));
    final current = list[index];
    list[index] = LookupItemResponse(
      id: current.id,
      codigo: request.codigo ?? current.codigo,
      descricao: request.descricao ?? current.descricao,
    );
    return Success(_wrap(null));
  }

  @override
  Future<Result<StandardResponse<void>>> toggleLookupItem(
    String tableName,
    String itemId,
    ToggleLookupItemRequest request,
  ) async {
    store.toggleItem(tableName, itemId, request.active);
    return Success(_wrap(null));
  }

  // ── Governance requests ─────────────────────────────────────────────────

  @override
  Future<Result<StandardResponse<List<LookupRequestResponse>>>>
  getLookupRequests() async {
    return Success(_wrap(List<LookupRequestResponse>.from(store.requests)));
  }

  @override
  Future<Result<StandardIdResponse>> createLookupRequest(
    CreateLookupRequestRequest request,
  ) async {
    final id = _nextId();
    store.addRequest(
      LookupRequestResponse(
        id: id,
        tableName: request.tableName,
        codigo: request.codigo,
        descricao: request.descricao,
        justificativa: request.justificativa,
        status: 'pending',
        createdAt: DateTime.now().toIso8601String(),
        requestedBy: 'fake-user-id',
      ),
    );
    return Success(_wrapId(id));
  }

  @override
  Future<Result<StandardResponse<void>>> approveLookupRequest(
    String requestId,
  ) async {
    store.approveRequest(requestId);
    return Success(_wrap(null));
  }

  @override
  Future<Result<StandardResponse<void>>> rejectLookupRequest(
    String requestId,
  ) async {
    store.rejectRequest(requestId);
    return Success(_wrap(null));
  }
}
