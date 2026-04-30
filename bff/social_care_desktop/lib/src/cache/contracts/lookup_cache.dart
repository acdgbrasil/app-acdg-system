import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../_shared/cached.dart';

/// Desktop-only Read Model for the two governance entities: lookup
/// items (each keyed by `tableName`) and lookup change requests.
///
/// `tableName` has FTS5 search (`searchTables`) for typeahead UX. The
/// `codigo` / `descricao` of items inside a table are NOT indexed —
/// consumers iterate the small in-memory list returned by `listItems`.
///
/// `findItemById` and `findRequestById` return a [Cached] envelope so
/// orchestrating use cases (A18b-v2) can read `version` for
/// optimistic-locking on `update_lookup_item` / `toggle_lookup_item`
/// and `approve_lookup_request` / `reject_lookup_request` mutations.
abstract interface class LookupCache {
  // ── Lookup items ─────────────────────────────────────────────────────
  Future<Result<Cached<LookupItemResponse>?>> findItemById(
    String tableName,
    String itemId,
  );

  Future<Result<List<LookupItemResponse>>> listItems(String tableName);

  Future<Result<List<String>>> listAllTables();

  /// FTS5 search over distinct cached `tableName`s. Prefix matches
  /// supported.
  Future<Result<List<String>>> searchTables(String term);

  Future<Result<void>> upsertItem(
    String tableName,
    LookupItemResponse dto, {
    required int version,
  });

  Future<Result<void>> deleteItem(String tableName, String itemId);

  /// Wipe items belonging to a single `tableName`.
  Future<Result<void>> clearTable(String tableName);

  // ── Lookup requests (governance approval workflow) ───────────────────
  Future<Result<Cached<LookupRequestResponse>?>> findRequestById(
    String requestId,
  );

  Future<Result<List<LookupRequestResponse>>> listRequests({
    String? status,
    String? tableName,
    int? limit,
  });

  Future<Result<void>> upsertRequest(
    LookupRequestResponse dto, {
    required int version,
  });

  Future<Result<void>> deleteRequest(String requestId);

  // ── Cross-cutting ────────────────────────────────────────────────────
  /// Wipe both `lookup_items` and `lookup_requests`.
  Future<Result<void>> clear();
}
