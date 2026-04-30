// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:social_care_desktop/src/cache/_shared/cache_database.dart'
    as i1;
import 'package:social_care_desktop/src/cache/_shared/tables/protection_tables.drift.dart'
    as i2;
import 'package:drift/internal/modular.dart' as i3;

mixin $ProtectionDaoMixin on i0.DatabaseAccessor<i1.CacheDatabase> {
  i2.$ReferralsTable get referrals => i3.ReadDatabaseContainer(
    attachedDatabase,
  ).resultSet<i2.$ReferralsTable>('referrals');
  i2.$ViolationReportsTable get violationReports => i3.ReadDatabaseContainer(
    attachedDatabase,
  ).resultSet<i2.$ViolationReportsTable>('violation_reports');
  i2.$PlacementHistoriesTable get placementHistories =>
      i3.ReadDatabaseContainer(
        attachedDatabase,
      ).resultSet<i2.$PlacementHistoriesTable>('placement_histories');
  ProtectionDaoManager get managers => ProtectionDaoManager(this);
}

class ProtectionDaoManager {
  final $ProtectionDaoMixin _db;
  ProtectionDaoManager(this._db);
  i2.$$ReferralsTableTableManager get referrals =>
      i2.$$ReferralsTableTableManager(_db.attachedDatabase, _db.referrals);
  i2.$$ViolationReportsTableTableManager get violationReports =>
      i2.$$ViolationReportsTableTableManager(
        _db.attachedDatabase,
        _db.violationReports,
      );
  i2.$$PlacementHistoriesTableTableManager get placementHistories =>
      i2.$$PlacementHistoriesTableTableManager(
        _db.attachedDatabase,
        _db.placementHistories,
      );
}
