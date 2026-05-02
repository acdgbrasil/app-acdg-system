// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:social_care_desktop/src/cache/_shared/cache_database.dart'
    as i1;
import 'package:social_care_desktop/src/cache/_shared/tables/patients_table.drift.dart'
    as i2;
import 'package:drift/internal/modular.dart' as i3;

mixin $PatientDaoMixin on i0.DatabaseAccessor<i1.CacheDatabase> {
  i2.$PatientsTable get patients => i3.ReadDatabaseContainer(
    attachedDatabase,
  ).resultSet<i2.$PatientsTable>('patients');
  i2.$PatientSummariesTable get patientSummaries => i3.ReadDatabaseContainer(
    attachedDatabase,
  ).resultSet<i2.$PatientSummariesTable>('patient_summaries');
  PatientDaoManager get managers => PatientDaoManager(this);
}

class PatientDaoManager {
  final $PatientDaoMixin _db;
  PatientDaoManager(this._db);
  i2.$$PatientsTableTableManager get patients =>
      i2.$$PatientsTableTableManager(_db.attachedDatabase, _db.patients);
  i2.$$PatientSummariesTableTableManager get patientSummaries =>
      i2.$$PatientSummariesTableTableManager(
        _db.attachedDatabase,
        _db.patientSummaries,
      );
}
