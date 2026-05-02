// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:social_care_desktop/src/sync/_shared/tables/outbox_table.drift.dart'
    as i1;

abstract class $SyncDatabase extends i0.GeneratedDatabase {
  $SyncDatabase(i0.QueryExecutor e) : super(e);
  $SyncDatabaseManager get managers => $SyncDatabaseManager(this);
  late final i1.$OutboxTable outbox = i1.$OutboxTable(this);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [
    outbox,
    i1.outboxStatusCreatedIdx,
  ];
  @override
  i0.DriftDatabaseOptions get options =>
      const i0.DriftDatabaseOptions(storeDateTimeAsText: true);
}

class $SyncDatabaseManager {
  final $SyncDatabase _db;
  $SyncDatabaseManager(this._db);
  i1.$$OutboxTableTableManager get outbox =>
      i1.$$OutboxTableTableManager(_db, _db.outbox);
}
