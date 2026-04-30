// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:social_care_desktop/src/cache/_shared/cache_database.dart'
    as i1;
import 'package:social_care_desktop/src/cache/_shared/tables/care_table.drift.dart'
    as i2;
import 'package:drift/internal/modular.dart' as i3;

mixin $CareDaoMixin on i0.DatabaseAccessor<i1.CacheDatabase> {
  i2.$AppointmentsTable get appointments => i3.ReadDatabaseContainer(
    attachedDatabase,
  ).resultSet<i2.$AppointmentsTable>('appointments');
  CareDaoManager get managers => CareDaoManager(this);
}

class CareDaoManager {
  final $CareDaoMixin _db;
  CareDaoManager(this._db);
  i2.$$AppointmentsTableTableManager get appointments => i2
      .$$AppointmentsTableTableManager(_db.attachedDatabase, _db.appointments);
}
