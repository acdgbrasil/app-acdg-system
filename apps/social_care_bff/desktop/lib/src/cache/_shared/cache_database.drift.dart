// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:social_care_desktop/src/cache/_shared/tables/patients_table.drift.dart'
    as i1;
import 'package:social_care_desktop/src/cache/_shared/tables/care_table.drift.dart'
    as i2;
import 'package:social_care_desktop/src/cache/_shared/tables/protection_tables.drift.dart'
    as i3;
import 'package:social_care_desktop/src/cache/_shared/tables/audit_table.drift.dart'
    as i4;
import 'package:social_care_desktop/src/cache/_shared/tables/lookup_tables.drift.dart'
    as i5;

abstract class $CacheDatabase extends i0.GeneratedDatabase {
  $CacheDatabase(i0.QueryExecutor e) : super(e);
  $CacheDatabaseManager get managers => $CacheDatabaseManager(this);
  late final i1.$PatientsTable patients = i1.$PatientsTable(this);
  late final i1.$PatientSummariesTable patientSummaries = i1
      .$PatientSummariesTable(this);
  late final i2.$AppointmentsTable appointments = i2.$AppointmentsTable(this);
  late final i3.$ReferralsTable referrals = i3.$ReferralsTable(this);
  late final i3.$ViolationReportsTable violationReports = i3
      .$ViolationReportsTable(this);
  late final i3.$PlacementHistoriesTable placementHistories = i3
      .$PlacementHistoriesTable(this);
  late final i4.$AuditEntriesTable auditEntries = i4.$AuditEntriesTable(this);
  late final i5.$LookupItemsTable lookupItems = i5.$LookupItemsTable(this);
  late final i5.$LookupRequestsTable lookupRequests = i5.$LookupRequestsTable(
    this,
  );
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [
    patients,
    patientSummaries,
    appointments,
    referrals,
    violationReports,
    placementHistories,
    auditEntries,
    lookupItems,
    lookupRequests,
    i1.patientsPersonIdIdx,
    i1.patientsStatusIdx,
    i1.patientSummariesStatusIdx,
    i2.appointmentsPatientIdIdx,
    i3.referralsPatientIdIdx,
    i3.violationReportsPatientIdIdx,
    i4.auditEntriesPatientIdIdx,
    i4.auditEntriesEventTypeIdx,
    i5.lookupItemsLookupNameIdx,
    i5.lookupRequestsLookupNameIdx,
    i5.lookupRequestsStatusIdx,
  ];
  @override
  i0.DriftDatabaseOptions get options =>
      const i0.DriftDatabaseOptions(storeDateTimeAsText: true);
}

class $CacheDatabaseManager {
  final $CacheDatabase _db;
  $CacheDatabaseManager(this._db);
  i1.$$PatientsTableTableManager get patients =>
      i1.$$PatientsTableTableManager(_db, _db.patients);
  i1.$$PatientSummariesTableTableManager get patientSummaries =>
      i1.$$PatientSummariesTableTableManager(_db, _db.patientSummaries);
  i2.$$AppointmentsTableTableManager get appointments =>
      i2.$$AppointmentsTableTableManager(_db, _db.appointments);
  i3.$$ReferralsTableTableManager get referrals =>
      i3.$$ReferralsTableTableManager(_db, _db.referrals);
  i3.$$ViolationReportsTableTableManager get violationReports =>
      i3.$$ViolationReportsTableTableManager(_db, _db.violationReports);
  i3.$$PlacementHistoriesTableTableManager get placementHistories =>
      i3.$$PlacementHistoriesTableTableManager(_db, _db.placementHistories);
  i4.$$AuditEntriesTableTableManager get auditEntries =>
      i4.$$AuditEntriesTableTableManager(_db, _db.auditEntries);
  i5.$$LookupItemsTableTableManager get lookupItems =>
      i5.$$LookupItemsTableTableManager(_db, _db.lookupItems);
  i5.$$LookupRequestsTableTableManager get lookupRequests =>
      i5.$$LookupRequestsTableTableManager(_db, _db.lookupRequests);
}
