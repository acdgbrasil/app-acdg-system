// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:social_care_desktop/src/cache/_shared/cache_database.dart'
    as i1;
import 'package:social_care_desktop/src/cache/_shared/tables/audit_table.drift.dart'
    as i2;
import 'package:drift/internal/modular.dart' as i3;

mixin $AuditDaoMixin on i0.DatabaseAccessor<i1.CacheDatabase> {
  i2.$AuditEntriesTable get auditEntries => i3.ReadDatabaseContainer(
    attachedDatabase,
  ).resultSet<i2.$AuditEntriesTable>('audit_entries');
  AuditDaoManager get managers => AuditDaoManager(this);
}

class AuditDaoManager {
  final $AuditDaoMixin _db;
  AuditDaoManager(this._db);
  i2.$$AuditEntriesTableTableManager get auditEntries => i2
      .$$AuditEntriesTableTableManager(_db.attachedDatabase, _db.auditEntries);
}
