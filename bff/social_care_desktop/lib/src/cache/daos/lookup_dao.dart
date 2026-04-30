import 'package:drift/drift.dart';

import '../_shared/cache_database.dart';
import '../_shared/tables/lookup_tables.dart';
import '../_shared/tables/lookup_tables.drift.dart';
import 'lookup_dao.drift.dart';

@DriftAccessor(tables: [LookupItems, LookupRequests])
class LookupDao extends DatabaseAccessor<CacheDatabase> with $LookupDaoMixin {
  LookupDao(super.db);

  // ── Items ────────────────────────────────────────────────────────────
  Future<LookupItem?> findItemById(String tableName, String itemId) {
    return (select(lookupItems)
          ..where((l) => l.lookupName.equals(tableName) & l.id.equals(itemId)))
        .getSingleOrNull();
  }

  Future<List<LookupItem>> listItems(String tableName) {
    return (select(
      lookupItems,
    )..where((l) => l.lookupName.equals(tableName))).get();
  }

  Future<List<String>> listAllTableNames() async {
    final result = await customSelect(
      'SELECT DISTINCT lookup_name AS lookup_name FROM lookup_items',
      readsFrom: {lookupItems},
    ).get();
    return result.map((row) => row.read<String>('lookup_name')).toList();
  }

  /// FTS5 search via the `lookup_tables_fts` virtual table. Returns
  /// distinct cached `tableName`s (one entry per matching tableName,
  /// not per matched row).
  Future<List<String>> searchTableNames(String term) async {
    final sanitized = term.replaceAll("'", '').trim();
    if (sanitized.isEmpty) {
      return const [];
    }
    final result = await customSelect(
      'SELECT DISTINCT lookup_name AS lookup_name FROM lookup_items '
      'WHERE rowid IN ('
      '  SELECT rowid FROM lookup_tables_fts '
      "  WHERE lookup_tables_fts MATCH '${sanitized.toLowerCase()}*'"
      ')',
      readsFrom: {lookupItems},
    ).get();
    return result.map((row) => row.read<String>('lookup_name')).toList();
  }

  Future<void> upsertItem({
    required String tableName,
    required String id,
    required String payload,
    required DateTime cachedAt,
    required int version,
  }) {
    return into(lookupItems).insert(
      LookupItemsCompanion.insert(
        lookupName: tableName,
        id: id,
        payload: payload,
        cachedAt: cachedAt,
        version: version,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteItem(String tableName, String itemId) async {
    await (delete(
      lookupItems,
    )..where((l) => l.lookupName.equals(tableName) & l.id.equals(itemId))).go();
  }

  Future<void> clearItemsByTable(String tableName) async {
    await (delete(
      lookupItems,
    )..where((l) => l.lookupName.equals(tableName))).go();
  }

  Future<void> clearItems() => delete(lookupItems).go();

  // ── Requests ─────────────────────────────────────────────────────────
  Future<LookupRequest?> findRequestById(String requestId) {
    return (select(
      lookupRequests,
    )..where((r) => r.id.equals(requestId))).getSingleOrNull();
  }

  Future<List<LookupRequest>> listRequests({
    String? status,
    String? tableName,
    int? limit,
  }) {
    final q = select(lookupRequests);
    if (status != null) {
      q.where((r) => r.status.equals(status));
    }
    if (tableName != null) {
      q.where((r) => r.lookupName.equals(tableName));
    }
    if (limit != null) {
      q.limit(limit);
    }
    return q.get();
  }

  Future<void> upsertRequest({
    required String id,
    required String tableName,
    required String status,
    required String payload,
    required DateTime cachedAt,
    required int version,
  }) {
    return into(lookupRequests).insert(
      LookupRequestsCompanion.insert(
        id: id,
        lookupName: tableName,
        status: status,
        payload: payload,
        cachedAt: cachedAt,
        version: version,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteRequest(String requestId) async {
    await (delete(lookupRequests)..where((r) => r.id.equals(requestId))).go();
  }

  Future<void> clearRequests() => delete(lookupRequests).go();
}
