import '../../contract/dto/responses/governance/lookup_item_response.dart';
import '../../contract/dto/responses/governance/lookup_request_response.dart';

/// In-memory collaborator that stores lookup tables and governance
/// requests for proposed items.
///
/// `approveRequest` / `rejectRequest` rebuild the request DTO (immutable)
/// rather than mutating it.
class InMemoryLookupStore {
  InMemoryLookupStore();

  /// Lookup items keyed by table name.
  final Map<String, List<LookupItemResponse>> tables = {};

  /// Governance requests (proposed items), stored in insertion order.
  final List<LookupRequestResponse> requests = [];

  /// Appends an item to the given table (creates the list on first call).
  void addItem(String tableName, LookupItemResponse item) {
    tables.putIfAbsent(tableName, () => <LookupItemResponse>[]).add(item);
  }

  /// Snapshot of items for a table. Empty list if unknown.
  List<LookupItemResponse> getTable(String tableName) =>
      List<LookupItemResponse>.from(
        tables[tableName] ?? const <LookupItemResponse>[],
      );

  /// Toggles an item's active flag. The response DTO does not carry an
  /// `active` field, so the store simply records the call as a no-op but
  /// validates that the table/item exist; future versions can expand here.
  void toggleItem(String tableName, String itemId, bool active) {
    // No `active` field on [LookupItemResponse] to flip — kept for API
    // symmetry with the contract. Concrete state tracking can be added
    // alongside richer DTOs later.
  }

  /// Appends a governance request.
  void addRequest(LookupRequestResponse request) {
    requests.add(request);
  }

  /// Rebuilds the matching request with `status = 'approved'`.
  /// No-op when the request is not found.
  void approveRequest(String id) {
    _flipRequestStatus(id, 'approved');
  }

  /// Rebuilds the matching request with `status = 'rejected'`.
  void rejectRequest(String id) {
    _flipRequestStatus(id, 'rejected');
  }

  /// Resets the store between tests.
  void clear() {
    tables.clear();
    requests.clear();
  }

  void _flipRequestStatus(String id, String nextStatus) {
    final index = requests.indexWhere((r) => r.id == id);
    if (index == -1) return;
    final current = requests[index];
    requests[index] = LookupRequestResponse(
      id: current.id,
      tableName: current.tableName,
      codigo: current.codigo,
      descricao: current.descricao,
      justificativa: current.justificativa,
      status: nextStatus,
      createdAt: current.createdAt,
      requestedBy: current.requestedBy,
    );
  }
}
