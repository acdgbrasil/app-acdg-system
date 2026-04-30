// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:social_care_desktop/src/cache/_shared/cache_database.dart'
    as i1;
import 'package:social_care_desktop/src/cache/_shared/tables/lookup_tables.drift.dart'
    as i2;
import 'package:drift/internal/modular.dart' as i3;

mixin $LookupDaoMixin on i0.DatabaseAccessor<i1.CacheDatabase> {
  i2.$LookupItemsTable get lookupItems => i3.ReadDatabaseContainer(
    attachedDatabase,
  ).resultSet<i2.$LookupItemsTable>('lookup_items');
  i2.$LookupRequestsTable get lookupRequests => i3.ReadDatabaseContainer(
    attachedDatabase,
  ).resultSet<i2.$LookupRequestsTable>('lookup_requests');
  LookupDaoManager get managers => LookupDaoManager(this);
}

class LookupDaoManager {
  final $LookupDaoMixin _db;
  LookupDaoManager(this._db);
  i2.$$LookupItemsTableTableManager get lookupItems =>
      i2.$$LookupItemsTableTableManager(_db.attachedDatabase, _db.lookupItems);
  i2.$$LookupRequestsTableTableManager get lookupRequests =>
      i2.$$LookupRequestsTableTableManager(
        _db.attachedDatabase,
        _db.lookupRequests,
      );
}
