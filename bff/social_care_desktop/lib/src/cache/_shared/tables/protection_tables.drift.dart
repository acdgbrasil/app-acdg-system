// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:social_care_desktop/src/cache/_shared/tables/protection_tables.drift.dart'
    as i1;
import 'package:social_care_desktop/src/cache/_shared/tables/protection_tables.dart'
    as i2;

typedef $$ReferralsTableCreateCompanionBuilder =
    i1.ReferralsCompanion Function({
      required String patientId,
      required String id,
      required String payload,
      required DateTime cachedAt,
      required int version,
      i0.Value<int> rowid,
    });
typedef $$ReferralsTableUpdateCompanionBuilder =
    i1.ReferralsCompanion Function({
      i0.Value<String> patientId,
      i0.Value<String> id,
      i0.Value<String> payload,
      i0.Value<DateTime> cachedAt,
      i0.Value<int> version,
      i0.Value<int> rowid,
    });

class $$ReferralsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$ReferralsTable> {
  $$ReferralsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$ReferralsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$ReferralsTable> {
  $$ReferralsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$ReferralsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$ReferralsTable> {
  $$ReferralsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$ReferralsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$ReferralsTable,
          i1.Referral,
          i1.$$ReferralsTableFilterComposer,
          i1.$$ReferralsTableOrderingComposer,
          i1.$$ReferralsTableAnnotationComposer,
          $$ReferralsTableCreateCompanionBuilder,
          $$ReferralsTableUpdateCompanionBuilder,
          (
            i1.Referral,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$ReferralsTable,
              i1.Referral
            >,
          ),
          i1.Referral,
          i0.PrefetchHooks Function()
        > {
  $$ReferralsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$ReferralsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$ReferralsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$ReferralsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$ReferralsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> patientId = const i0.Value.absent(),
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> payload = const i0.Value.absent(),
                i0.Value<DateTime> cachedAt = const i0.Value.absent(),
                i0.Value<int> version = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.ReferralsCompanion(
                patientId: patientId,
                id: id,
                payload: payload,
                cachedAt: cachedAt,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String patientId,
                required String id,
                required String payload,
                required DateTime cachedAt,
                required int version,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.ReferralsCompanion.insert(
                patientId: patientId,
                id: id,
                payload: payload,
                cachedAt: cachedAt,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReferralsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$ReferralsTable,
      i1.Referral,
      i1.$$ReferralsTableFilterComposer,
      i1.$$ReferralsTableOrderingComposer,
      i1.$$ReferralsTableAnnotationComposer,
      $$ReferralsTableCreateCompanionBuilder,
      $$ReferralsTableUpdateCompanionBuilder,
      (
        i1.Referral,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$ReferralsTable,
          i1.Referral
        >,
      ),
      i1.Referral,
      i0.PrefetchHooks Function()
    >;
typedef $$ViolationReportsTableCreateCompanionBuilder =
    i1.ViolationReportsCompanion Function({
      required String patientId,
      required String id,
      required String payload,
      required DateTime cachedAt,
      required int version,
      i0.Value<int> rowid,
    });
typedef $$ViolationReportsTableUpdateCompanionBuilder =
    i1.ViolationReportsCompanion Function({
      i0.Value<String> patientId,
      i0.Value<String> id,
      i0.Value<String> payload,
      i0.Value<DateTime> cachedAt,
      i0.Value<int> version,
      i0.Value<int> rowid,
    });

class $$ViolationReportsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$ViolationReportsTable> {
  $$ViolationReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$ViolationReportsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$ViolationReportsTable> {
  $$ViolationReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$ViolationReportsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$ViolationReportsTable> {
  $$ViolationReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$ViolationReportsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$ViolationReportsTable,
          i1.ViolationReport,
          i1.$$ViolationReportsTableFilterComposer,
          i1.$$ViolationReportsTableOrderingComposer,
          i1.$$ViolationReportsTableAnnotationComposer,
          $$ViolationReportsTableCreateCompanionBuilder,
          $$ViolationReportsTableUpdateCompanionBuilder,
          (
            i1.ViolationReport,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$ViolationReportsTable,
              i1.ViolationReport
            >,
          ),
          i1.ViolationReport,
          i0.PrefetchHooks Function()
        > {
  $$ViolationReportsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$ViolationReportsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$ViolationReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => i1
              .$$ViolationReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$ViolationReportsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                i0.Value<String> patientId = const i0.Value.absent(),
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> payload = const i0.Value.absent(),
                i0.Value<DateTime> cachedAt = const i0.Value.absent(),
                i0.Value<int> version = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.ViolationReportsCompanion(
                patientId: patientId,
                id: id,
                payload: payload,
                cachedAt: cachedAt,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String patientId,
                required String id,
                required String payload,
                required DateTime cachedAt,
                required int version,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.ViolationReportsCompanion.insert(
                patientId: patientId,
                id: id,
                payload: payload,
                cachedAt: cachedAt,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ViolationReportsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$ViolationReportsTable,
      i1.ViolationReport,
      i1.$$ViolationReportsTableFilterComposer,
      i1.$$ViolationReportsTableOrderingComposer,
      i1.$$ViolationReportsTableAnnotationComposer,
      $$ViolationReportsTableCreateCompanionBuilder,
      $$ViolationReportsTableUpdateCompanionBuilder,
      (
        i1.ViolationReport,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$ViolationReportsTable,
          i1.ViolationReport
        >,
      ),
      i1.ViolationReport,
      i0.PrefetchHooks Function()
    >;
typedef $$PlacementHistoriesTableCreateCompanionBuilder =
    i1.PlacementHistoriesCompanion Function({
      required String patientId,
      required String payload,
      required DateTime cachedAt,
      required int version,
      i0.Value<int> rowid,
    });
typedef $$PlacementHistoriesTableUpdateCompanionBuilder =
    i1.PlacementHistoriesCompanion Function({
      i0.Value<String> patientId,
      i0.Value<String> payload,
      i0.Value<DateTime> cachedAt,
      i0.Value<int> version,
      i0.Value<int> rowid,
    });

class $$PlacementHistoriesTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PlacementHistoriesTable> {
  $$PlacementHistoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$PlacementHistoriesTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PlacementHistoriesTable> {
  $$PlacementHistoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$PlacementHistoriesTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PlacementHistoriesTable> {
  $$PlacementHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  i0.GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$PlacementHistoriesTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$PlacementHistoriesTable,
          i1.PlacementHistory,
          i1.$$PlacementHistoriesTableFilterComposer,
          i1.$$PlacementHistoriesTableOrderingComposer,
          i1.$$PlacementHistoriesTableAnnotationComposer,
          $$PlacementHistoriesTableCreateCompanionBuilder,
          $$PlacementHistoriesTableUpdateCompanionBuilder,
          (
            i1.PlacementHistory,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$PlacementHistoriesTable,
              i1.PlacementHistory
            >,
          ),
          i1.PlacementHistory,
          i0.PrefetchHooks Function()
        > {
  $$PlacementHistoriesTableTableManager(
    i0.GeneratedDatabase db,
    i1.$PlacementHistoriesTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => i1
              .$$PlacementHistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$PlacementHistoriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              i1.$$PlacementHistoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                i0.Value<String> patientId = const i0.Value.absent(),
                i0.Value<String> payload = const i0.Value.absent(),
                i0.Value<DateTime> cachedAt = const i0.Value.absent(),
                i0.Value<int> version = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.PlacementHistoriesCompanion(
                patientId: patientId,
                payload: payload,
                cachedAt: cachedAt,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String patientId,
                required String payload,
                required DateTime cachedAt,
                required int version,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.PlacementHistoriesCompanion.insert(
                patientId: patientId,
                payload: payload,
                cachedAt: cachedAt,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlacementHistoriesTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$PlacementHistoriesTable,
      i1.PlacementHistory,
      i1.$$PlacementHistoriesTableFilterComposer,
      i1.$$PlacementHistoriesTableOrderingComposer,
      i1.$$PlacementHistoriesTableAnnotationComposer,
      $$PlacementHistoriesTableCreateCompanionBuilder,
      $$PlacementHistoriesTableUpdateCompanionBuilder,
      (
        i1.PlacementHistory,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$PlacementHistoriesTable,
          i1.PlacementHistory
        >,
      ),
      i1.PlacementHistory,
      i0.PrefetchHooks Function()
    >;
i0.Index get referralsPatientIdIdx => i0.Index(
  'referrals_patientId_idx',
  'CREATE INDEX referrals_patientId_idx ON referrals (patient_id)',
);

class $ReferralsTable extends i2.Referrals
    with i0.TableInfo<$ReferralsTable, i1.Referral> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReferralsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _patientIdMeta = const i0.VerificationMeta(
    'patientId',
  );
  @override
  late final i0.GeneratedColumn<String> patientId = i0.GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<String> id = i0.GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _payloadMeta = const i0.VerificationMeta(
    'payload',
  );
  @override
  late final i0.GeneratedColumn<String> payload = i0.GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _cachedAtMeta = const i0.VerificationMeta(
    'cachedAt',
  );
  @override
  late final i0.GeneratedColumn<DateTime> cachedAt =
      i0.GeneratedColumn<DateTime>(
        'cached_at',
        aliasedName,
        false,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _versionMeta = const i0.VerificationMeta(
    'version',
  );
  @override
  late final i0.GeneratedColumn<int> version = i0.GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    patientId,
    id,
    payload,
    cachedAt,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'referrals';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.Referral> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {patientId, id};
  @override
  i1.Referral map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Referral(
      patientId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $ReferralsTable createAlias(String alias) {
    return $ReferralsTable(attachedDatabase, alias);
  }
}

class Referral extends i0.DataClass implements i0.Insertable<i1.Referral> {
  final String patientId;
  final String id;
  final String payload;
  final DateTime cachedAt;
  final int version;
  const Referral({
    required this.patientId,
    required this.id,
    required this.payload,
    required this.cachedAt,
    required this.version,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['patient_id'] = i0.Variable<String>(patientId);
    map['id'] = i0.Variable<String>(id);
    map['payload'] = i0.Variable<String>(payload);
    map['cached_at'] = i0.Variable<DateTime>(cachedAt);
    map['version'] = i0.Variable<int>(version);
    return map;
  }

  i1.ReferralsCompanion toCompanion(bool nullToAbsent) {
    return i1.ReferralsCompanion(
      patientId: i0.Value(patientId),
      id: i0.Value(id),
      payload: i0.Value(payload),
      cachedAt: i0.Value(cachedAt),
      version: i0.Value(version),
    );
  }

  factory Referral.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return Referral(
      patientId: serializer.fromJson<String>(json['patientId']),
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'patientId': serializer.toJson<String>(patientId),
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'version': serializer.toJson<int>(version),
    };
  }

  i1.Referral copyWith({
    String? patientId,
    String? id,
    String? payload,
    DateTime? cachedAt,
    int? version,
  }) => i1.Referral(
    patientId: patientId ?? this.patientId,
    id: id ?? this.id,
    payload: payload ?? this.payload,
    cachedAt: cachedAt ?? this.cachedAt,
    version: version ?? this.version,
  );
  Referral copyWithCompanion(i1.ReferralsCompanion data) {
    return Referral(
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Referral(')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(patientId, id, payload, cachedAt, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.Referral &&
          other.patientId == this.patientId &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.cachedAt == this.cachedAt &&
          other.version == this.version);
}

class ReferralsCompanion extends i0.UpdateCompanion<i1.Referral> {
  final i0.Value<String> patientId;
  final i0.Value<String> id;
  final i0.Value<String> payload;
  final i0.Value<DateTime> cachedAt;
  final i0.Value<int> version;
  final i0.Value<int> rowid;
  const ReferralsCompanion({
    this.patientId = const i0.Value.absent(),
    this.id = const i0.Value.absent(),
    this.payload = const i0.Value.absent(),
    this.cachedAt = const i0.Value.absent(),
    this.version = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  ReferralsCompanion.insert({
    required String patientId,
    required String id,
    required String payload,
    required DateTime cachedAt,
    required int version,
    this.rowid = const i0.Value.absent(),
  }) : patientId = i0.Value(patientId),
       id = i0.Value(id),
       payload = i0.Value(payload),
       cachedAt = i0.Value(cachedAt),
       version = i0.Value(version);
  static i0.Insertable<i1.Referral> custom({
    i0.Expression<String>? patientId,
    i0.Expression<String>? id,
    i0.Expression<String>? payload,
    i0.Expression<DateTime>? cachedAt,
    i0.Expression<int>? version,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (patientId != null) 'patient_id': patientId,
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.ReferralsCompanion copyWith({
    i0.Value<String>? patientId,
    i0.Value<String>? id,
    i0.Value<String>? payload,
    i0.Value<DateTime>? cachedAt,
    i0.Value<int>? version,
    i0.Value<int>? rowid,
  }) {
    return i1.ReferralsCompanion(
      patientId: patientId ?? this.patientId,
      id: id ?? this.id,
      payload: payload ?? this.payload,
      cachedAt: cachedAt ?? this.cachedAt,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (patientId.present) {
      map['patient_id'] = i0.Variable<String>(patientId.value);
    }
    if (id.present) {
      map['id'] = i0.Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = i0.Variable<String>(payload.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = i0.Variable<DateTime>(cachedAt.value);
    }
    if (version.present) {
      map['version'] = i0.Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReferralsCompanion(')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

i0.Index get violationReportsPatientIdIdx => i0.Index(
  'violation_reports_patientId_idx',
  'CREATE INDEX violation_reports_patientId_idx ON violation_reports (patient_id)',
);

class $ViolationReportsTable extends i2.ViolationReports
    with i0.TableInfo<$ViolationReportsTable, i1.ViolationReport> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ViolationReportsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _patientIdMeta = const i0.VerificationMeta(
    'patientId',
  );
  @override
  late final i0.GeneratedColumn<String> patientId = i0.GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<String> id = i0.GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _payloadMeta = const i0.VerificationMeta(
    'payload',
  );
  @override
  late final i0.GeneratedColumn<String> payload = i0.GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _cachedAtMeta = const i0.VerificationMeta(
    'cachedAt',
  );
  @override
  late final i0.GeneratedColumn<DateTime> cachedAt =
      i0.GeneratedColumn<DateTime>(
        'cached_at',
        aliasedName,
        false,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _versionMeta = const i0.VerificationMeta(
    'version',
  );
  @override
  late final i0.GeneratedColumn<int> version = i0.GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    patientId,
    id,
    payload,
    cachedAt,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'violation_reports';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.ViolationReport> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {patientId, id};
  @override
  i1.ViolationReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.ViolationReport(
      patientId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $ViolationReportsTable createAlias(String alias) {
    return $ViolationReportsTable(attachedDatabase, alias);
  }
}

class ViolationReport extends i0.DataClass
    implements i0.Insertable<i1.ViolationReport> {
  final String patientId;
  final String id;
  final String payload;
  final DateTime cachedAt;
  final int version;
  const ViolationReport({
    required this.patientId,
    required this.id,
    required this.payload,
    required this.cachedAt,
    required this.version,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['patient_id'] = i0.Variable<String>(patientId);
    map['id'] = i0.Variable<String>(id);
    map['payload'] = i0.Variable<String>(payload);
    map['cached_at'] = i0.Variable<DateTime>(cachedAt);
    map['version'] = i0.Variable<int>(version);
    return map;
  }

  i1.ViolationReportsCompanion toCompanion(bool nullToAbsent) {
    return i1.ViolationReportsCompanion(
      patientId: i0.Value(patientId),
      id: i0.Value(id),
      payload: i0.Value(payload),
      cachedAt: i0.Value(cachedAt),
      version: i0.Value(version),
    );
  }

  factory ViolationReport.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return ViolationReport(
      patientId: serializer.fromJson<String>(json['patientId']),
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'patientId': serializer.toJson<String>(patientId),
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'version': serializer.toJson<int>(version),
    };
  }

  i1.ViolationReport copyWith({
    String? patientId,
    String? id,
    String? payload,
    DateTime? cachedAt,
    int? version,
  }) => i1.ViolationReport(
    patientId: patientId ?? this.patientId,
    id: id ?? this.id,
    payload: payload ?? this.payload,
    cachedAt: cachedAt ?? this.cachedAt,
    version: version ?? this.version,
  );
  ViolationReport copyWithCompanion(i1.ViolationReportsCompanion data) {
    return ViolationReport(
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ViolationReport(')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(patientId, id, payload, cachedAt, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.ViolationReport &&
          other.patientId == this.patientId &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.cachedAt == this.cachedAt &&
          other.version == this.version);
}

class ViolationReportsCompanion extends i0.UpdateCompanion<i1.ViolationReport> {
  final i0.Value<String> patientId;
  final i0.Value<String> id;
  final i0.Value<String> payload;
  final i0.Value<DateTime> cachedAt;
  final i0.Value<int> version;
  final i0.Value<int> rowid;
  const ViolationReportsCompanion({
    this.patientId = const i0.Value.absent(),
    this.id = const i0.Value.absent(),
    this.payload = const i0.Value.absent(),
    this.cachedAt = const i0.Value.absent(),
    this.version = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  ViolationReportsCompanion.insert({
    required String patientId,
    required String id,
    required String payload,
    required DateTime cachedAt,
    required int version,
    this.rowid = const i0.Value.absent(),
  }) : patientId = i0.Value(patientId),
       id = i0.Value(id),
       payload = i0.Value(payload),
       cachedAt = i0.Value(cachedAt),
       version = i0.Value(version);
  static i0.Insertable<i1.ViolationReport> custom({
    i0.Expression<String>? patientId,
    i0.Expression<String>? id,
    i0.Expression<String>? payload,
    i0.Expression<DateTime>? cachedAt,
    i0.Expression<int>? version,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (patientId != null) 'patient_id': patientId,
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.ViolationReportsCompanion copyWith({
    i0.Value<String>? patientId,
    i0.Value<String>? id,
    i0.Value<String>? payload,
    i0.Value<DateTime>? cachedAt,
    i0.Value<int>? version,
    i0.Value<int>? rowid,
  }) {
    return i1.ViolationReportsCompanion(
      patientId: patientId ?? this.patientId,
      id: id ?? this.id,
      payload: payload ?? this.payload,
      cachedAt: cachedAt ?? this.cachedAt,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (patientId.present) {
      map['patient_id'] = i0.Variable<String>(patientId.value);
    }
    if (id.present) {
      map['id'] = i0.Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = i0.Variable<String>(payload.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = i0.Variable<DateTime>(cachedAt.value);
    }
    if (version.present) {
      map['version'] = i0.Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ViolationReportsCompanion(')
          ..write('patientId: $patientId, ')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlacementHistoriesTable extends i2.PlacementHistories
    with i0.TableInfo<$PlacementHistoriesTable, i1.PlacementHistory> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlacementHistoriesTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _patientIdMeta = const i0.VerificationMeta(
    'patientId',
  );
  @override
  late final i0.GeneratedColumn<String> patientId = i0.GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _payloadMeta = const i0.VerificationMeta(
    'payload',
  );
  @override
  late final i0.GeneratedColumn<String> payload = i0.GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _cachedAtMeta = const i0.VerificationMeta(
    'cachedAt',
  );
  @override
  late final i0.GeneratedColumn<DateTime> cachedAt =
      i0.GeneratedColumn<DateTime>(
        'cached_at',
        aliasedName,
        false,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _versionMeta = const i0.VerificationMeta(
    'version',
  );
  @override
  late final i0.GeneratedColumn<int> version = i0.GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    patientId,
    payload,
    cachedAt,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'placement_histories';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.PlacementHistory> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {patientId};
  @override
  i1.PlacementHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.PlacementHistory(
      patientId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $PlacementHistoriesTable createAlias(String alias) {
    return $PlacementHistoriesTable(attachedDatabase, alias);
  }
}

class PlacementHistory extends i0.DataClass
    implements i0.Insertable<i1.PlacementHistory> {
  final String patientId;
  final String payload;
  final DateTime cachedAt;
  final int version;
  const PlacementHistory({
    required this.patientId,
    required this.payload,
    required this.cachedAt,
    required this.version,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['patient_id'] = i0.Variable<String>(patientId);
    map['payload'] = i0.Variable<String>(payload);
    map['cached_at'] = i0.Variable<DateTime>(cachedAt);
    map['version'] = i0.Variable<int>(version);
    return map;
  }

  i1.PlacementHistoriesCompanion toCompanion(bool nullToAbsent) {
    return i1.PlacementHistoriesCompanion(
      patientId: i0.Value(patientId),
      payload: i0.Value(payload),
      cachedAt: i0.Value(cachedAt),
      version: i0.Value(version),
    );
  }

  factory PlacementHistory.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return PlacementHistory(
      patientId: serializer.fromJson<String>(json['patientId']),
      payload: serializer.fromJson<String>(json['payload']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'patientId': serializer.toJson<String>(patientId),
      'payload': serializer.toJson<String>(payload),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'version': serializer.toJson<int>(version),
    };
  }

  i1.PlacementHistory copyWith({
    String? patientId,
    String? payload,
    DateTime? cachedAt,
    int? version,
  }) => i1.PlacementHistory(
    patientId: patientId ?? this.patientId,
    payload: payload ?? this.payload,
    cachedAt: cachedAt ?? this.cachedAt,
    version: version ?? this.version,
  );
  PlacementHistory copyWithCompanion(i1.PlacementHistoriesCompanion data) {
    return PlacementHistory(
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      payload: data.payload.present ? data.payload.value : this.payload,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlacementHistory(')
          ..write('patientId: $patientId, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(patientId, payload, cachedAt, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.PlacementHistory &&
          other.patientId == this.patientId &&
          other.payload == this.payload &&
          other.cachedAt == this.cachedAt &&
          other.version == this.version);
}

class PlacementHistoriesCompanion
    extends i0.UpdateCompanion<i1.PlacementHistory> {
  final i0.Value<String> patientId;
  final i0.Value<String> payload;
  final i0.Value<DateTime> cachedAt;
  final i0.Value<int> version;
  final i0.Value<int> rowid;
  const PlacementHistoriesCompanion({
    this.patientId = const i0.Value.absent(),
    this.payload = const i0.Value.absent(),
    this.cachedAt = const i0.Value.absent(),
    this.version = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  PlacementHistoriesCompanion.insert({
    required String patientId,
    required String payload,
    required DateTime cachedAt,
    required int version,
    this.rowid = const i0.Value.absent(),
  }) : patientId = i0.Value(patientId),
       payload = i0.Value(payload),
       cachedAt = i0.Value(cachedAt),
       version = i0.Value(version);
  static i0.Insertable<i1.PlacementHistory> custom({
    i0.Expression<String>? patientId,
    i0.Expression<String>? payload,
    i0.Expression<DateTime>? cachedAt,
    i0.Expression<int>? version,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (patientId != null) 'patient_id': patientId,
      if (payload != null) 'payload': payload,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.PlacementHistoriesCompanion copyWith({
    i0.Value<String>? patientId,
    i0.Value<String>? payload,
    i0.Value<DateTime>? cachedAt,
    i0.Value<int>? version,
    i0.Value<int>? rowid,
  }) {
    return i1.PlacementHistoriesCompanion(
      patientId: patientId ?? this.patientId,
      payload: payload ?? this.payload,
      cachedAt: cachedAt ?? this.cachedAt,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (patientId.present) {
      map['patient_id'] = i0.Variable<String>(patientId.value);
    }
    if (payload.present) {
      map['payload'] = i0.Variable<String>(payload.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = i0.Variable<DateTime>(cachedAt.value);
    }
    if (version.present) {
      map['version'] = i0.Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlacementHistoriesCompanion(')
          ..write('patientId: $patientId, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}
