import 'package:drift/drift.dart';

import '../_shared/cache_database.dart';
import '../_shared/tables/audit_table.dart';
import '../_shared/tables/audit_table.drift.dart';
import 'audit_dao.drift.dart';

@DriftAccessor(tables: [AuditEntries])
class AuditDao extends DatabaseAccessor<CacheDatabase> with $AuditDaoMixin {
  AuditDao(super.db);

  Future<AuditEntry?> findById(String entryId) {
    return (select(
      auditEntries,
    )..where((a) => a.id.equals(entryId))).getSingleOrNull();
  }

  Future<List<AuditEntry>> listByPatient(
    String patientId, {
    String? eventType,
    int? limit,
    int? offset,
  }) {
    final q = select(auditEntries)..where((a) => a.patientId.equals(patientId));
    if (eventType != null) {
      q.where((a) => a.eventType.equals(eventType));
    }
    if (limit != null || offset != null) {
      q.limit(limit ?? 1 << 30, offset: offset);
    }
    return q.get();
  }

  Future<void> upsert({
    required String id,
    required String patientId,
    required String eventType,
    required String payload,
    required DateTime cachedAt,
    required int version,
  }) {
    return into(auditEntries).insert(
      AuditEntriesCompanion.insert(
        id: id,
        patientId: patientId,
        eventType: eventType,
        payload: payload,
        cachedAt: cachedAt,
        version: version,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteById(String entryId) async {
    await (delete(auditEntries)..where((a) => a.id.equals(entryId))).go();
  }

  Future<void> clearAll() => delete(auditEntries).go();
}
