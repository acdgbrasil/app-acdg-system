// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:persistence/src/tables/cached_patients.drift.dart' as i1;
import 'package:persistence/src/tables/sync_actions.drift.dart' as i2;
import 'package:persistence/src/tables/cached_lookups.drift.dart' as i3;

abstract class $AcdgDatabase extends i0.GeneratedDatabase {
  $AcdgDatabase(i0.QueryExecutor e) : super(e);
  $AcdgDatabaseManager get managers => $AcdgDatabaseManager(this);
  late final i1.$CachedPatientsTable cachedPatients = i1.$CachedPatientsTable(
    this,
  );
  late final i2.$SyncActionsTable syncActions = i2.$SyncActionsTable(this);
  late final i3.$CachedLookupsTable cachedLookups = i3.$CachedLookupsTable(
    this,
  );
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [
    cachedPatients,
    syncActions,
    cachedLookups,
  ];
  @override
  i0.DriftDatabaseOptions get options =>
      const i0.DriftDatabaseOptions(storeDateTimeAsText: true);
}

class $AcdgDatabaseManager {
  final $AcdgDatabase _db;
  $AcdgDatabaseManager(this._db);
  i1.$$CachedPatientsTableTableManager get cachedPatients =>
      i1.$$CachedPatientsTableTableManager(_db, _db.cachedPatients);
  i2.$$SyncActionsTableTableManager get syncActions =>
      i2.$$SyncActionsTableTableManager(_db, _db.syncActions);
  i3.$$CachedLookupsTableTableManager get cachedLookups =>
      i3.$$CachedLookupsTableTableManager(_db, _db.cachedLookups);
}
