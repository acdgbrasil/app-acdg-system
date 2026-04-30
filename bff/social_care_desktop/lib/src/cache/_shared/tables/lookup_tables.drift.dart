// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:social_care_desktop/src/cache/_shared/tables/lookup_tables.drift.dart'
    as i1;
import 'package:social_care_desktop/src/cache/_shared/tables/lookup_tables.dart'
    as i2;

typedef $$LookupItemsTableCreateCompanionBuilder =
    i1.LookupItemsCompanion Function({
      required String lookupName,
      required String id,
      required String payload,
      required DateTime cachedAt,
      required int version,
      i0.Value<int> rowid,
    });
typedef $$LookupItemsTableUpdateCompanionBuilder =
    i1.LookupItemsCompanion Function({
      i0.Value<String> lookupName,
      i0.Value<String> id,
      i0.Value<String> payload,
      i0.Value<DateTime> cachedAt,
      i0.Value<int> version,
      i0.Value<int> rowid,
    });

class $$LookupItemsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$LookupItemsTable> {
  $$LookupItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get lookupName => $composableBuilder(
    column: $table.lookupName,
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

class $$LookupItemsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$LookupItemsTable> {
  $$LookupItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get lookupName => $composableBuilder(
    column: $table.lookupName,
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

class $$LookupItemsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$LookupItemsTable> {
  $$LookupItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get lookupName => $composableBuilder(
    column: $table.lookupName,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$LookupItemsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$LookupItemsTable,
          i1.LookupItem,
          i1.$$LookupItemsTableFilterComposer,
          i1.$$LookupItemsTableOrderingComposer,
          i1.$$LookupItemsTableAnnotationComposer,
          $$LookupItemsTableCreateCompanionBuilder,
          $$LookupItemsTableUpdateCompanionBuilder,
          (
            i1.LookupItem,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$LookupItemsTable,
              i1.LookupItem
            >,
          ),
          i1.LookupItem,
          i0.PrefetchHooks Function()
        > {
  $$LookupItemsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$LookupItemsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$LookupItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$LookupItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$LookupItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> lookupName = const i0.Value.absent(),
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> payload = const i0.Value.absent(),
                i0.Value<DateTime> cachedAt = const i0.Value.absent(),
                i0.Value<int> version = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.LookupItemsCompanion(
                lookupName: lookupName,
                id: id,
                payload: payload,
                cachedAt: cachedAt,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lookupName,
                required String id,
                required String payload,
                required DateTime cachedAt,
                required int version,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.LookupItemsCompanion.insert(
                lookupName: lookupName,
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

typedef $$LookupItemsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$LookupItemsTable,
      i1.LookupItem,
      i1.$$LookupItemsTableFilterComposer,
      i1.$$LookupItemsTableOrderingComposer,
      i1.$$LookupItemsTableAnnotationComposer,
      $$LookupItemsTableCreateCompanionBuilder,
      $$LookupItemsTableUpdateCompanionBuilder,
      (
        i1.LookupItem,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$LookupItemsTable,
          i1.LookupItem
        >,
      ),
      i1.LookupItem,
      i0.PrefetchHooks Function()
    >;
typedef $$LookupRequestsTableCreateCompanionBuilder =
    i1.LookupRequestsCompanion Function({
      required String id,
      required String lookupName,
      required String status,
      required String payload,
      required DateTime cachedAt,
      required int version,
      i0.Value<int> rowid,
    });
typedef $$LookupRequestsTableUpdateCompanionBuilder =
    i1.LookupRequestsCompanion Function({
      i0.Value<String> id,
      i0.Value<String> lookupName,
      i0.Value<String> status,
      i0.Value<String> payload,
      i0.Value<DateTime> cachedAt,
      i0.Value<int> version,
      i0.Value<int> rowid,
    });

class $$LookupRequestsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$LookupRequestsTable> {
  $$LookupRequestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get lookupName => $composableBuilder(
    column: $table.lookupName,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
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

class $$LookupRequestsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$LookupRequestsTable> {
  $$LookupRequestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get lookupName => $composableBuilder(
    column: $table.lookupName,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
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

class $$LookupRequestsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$LookupRequestsTable> {
  $$LookupRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get lookupName => $composableBuilder(
    column: $table.lookupName,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  i0.GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$LookupRequestsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$LookupRequestsTable,
          i1.LookupRequest,
          i1.$$LookupRequestsTableFilterComposer,
          i1.$$LookupRequestsTableOrderingComposer,
          i1.$$LookupRequestsTableAnnotationComposer,
          $$LookupRequestsTableCreateCompanionBuilder,
          $$LookupRequestsTableUpdateCompanionBuilder,
          (
            i1.LookupRequest,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$LookupRequestsTable,
              i1.LookupRequest
            >,
          ),
          i1.LookupRequest,
          i0.PrefetchHooks Function()
        > {
  $$LookupRequestsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$LookupRequestsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$LookupRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$LookupRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => i1
              .$$LookupRequestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> lookupName = const i0.Value.absent(),
                i0.Value<String> status = const i0.Value.absent(),
                i0.Value<String> payload = const i0.Value.absent(),
                i0.Value<DateTime> cachedAt = const i0.Value.absent(),
                i0.Value<int> version = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.LookupRequestsCompanion(
                id: id,
                lookupName: lookupName,
                status: status,
                payload: payload,
                cachedAt: cachedAt,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String lookupName,
                required String status,
                required String payload,
                required DateTime cachedAt,
                required int version,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.LookupRequestsCompanion.insert(
                id: id,
                lookupName: lookupName,
                status: status,
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

typedef $$LookupRequestsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$LookupRequestsTable,
      i1.LookupRequest,
      i1.$$LookupRequestsTableFilterComposer,
      i1.$$LookupRequestsTableOrderingComposer,
      i1.$$LookupRequestsTableAnnotationComposer,
      $$LookupRequestsTableCreateCompanionBuilder,
      $$LookupRequestsTableUpdateCompanionBuilder,
      (
        i1.LookupRequest,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$LookupRequestsTable,
          i1.LookupRequest
        >,
      ),
      i1.LookupRequest,
      i0.PrefetchHooks Function()
    >;
i0.Index get lookupItemsLookupNameIdx => i0.Index(
  'lookup_items_lookupName_idx',
  'CREATE INDEX lookup_items_lookupName_idx ON lookup_items (lookup_name)',
);

class $LookupItemsTable extends i2.LookupItems
    with i0.TableInfo<$LookupItemsTable, i1.LookupItem> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LookupItemsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _lookupNameMeta = const i0.VerificationMeta(
    'lookupName',
  );
  @override
  late final i0.GeneratedColumn<String> lookupName = i0.GeneratedColumn<String>(
    'lookup_name',
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
    lookupName,
    id,
    payload,
    cachedAt,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lookup_items';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.LookupItem> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lookup_name')) {
      context.handle(
        _lookupNameMeta,
        lookupName.isAcceptableOrUnknown(data['lookup_name']!, _lookupNameMeta),
      );
    } else if (isInserting) {
      context.missing(_lookupNameMeta);
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
  Set<i0.GeneratedColumn> get $primaryKey => {lookupName, id};
  @override
  i1.LookupItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.LookupItem(
      lookupName: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}lookup_name'],
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
  $LookupItemsTable createAlias(String alias) {
    return $LookupItemsTable(attachedDatabase, alias);
  }
}

class LookupItem extends i0.DataClass implements i0.Insertable<i1.LookupItem> {
  final String lookupName;
  final String id;
  final String payload;
  final DateTime cachedAt;
  final int version;
  const LookupItem({
    required this.lookupName,
    required this.id,
    required this.payload,
    required this.cachedAt,
    required this.version,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['lookup_name'] = i0.Variable<String>(lookupName);
    map['id'] = i0.Variable<String>(id);
    map['payload'] = i0.Variable<String>(payload);
    map['cached_at'] = i0.Variable<DateTime>(cachedAt);
    map['version'] = i0.Variable<int>(version);
    return map;
  }

  i1.LookupItemsCompanion toCompanion(bool nullToAbsent) {
    return i1.LookupItemsCompanion(
      lookupName: i0.Value(lookupName),
      id: i0.Value(id),
      payload: i0.Value(payload),
      cachedAt: i0.Value(cachedAt),
      version: i0.Value(version),
    );
  }

  factory LookupItem.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return LookupItem(
      lookupName: serializer.fromJson<String>(json['lookupName']),
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
      'lookupName': serializer.toJson<String>(lookupName),
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'version': serializer.toJson<int>(version),
    };
  }

  i1.LookupItem copyWith({
    String? lookupName,
    String? id,
    String? payload,
    DateTime? cachedAt,
    int? version,
  }) => i1.LookupItem(
    lookupName: lookupName ?? this.lookupName,
    id: id ?? this.id,
    payload: payload ?? this.payload,
    cachedAt: cachedAt ?? this.cachedAt,
    version: version ?? this.version,
  );
  LookupItem copyWithCompanion(i1.LookupItemsCompanion data) {
    return LookupItem(
      lookupName: data.lookupName.present
          ? data.lookupName.value
          : this.lookupName,
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LookupItem(')
          ..write('lookupName: $lookupName, ')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(lookupName, id, payload, cachedAt, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.LookupItem &&
          other.lookupName == this.lookupName &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.cachedAt == this.cachedAt &&
          other.version == this.version);
}

class LookupItemsCompanion extends i0.UpdateCompanion<i1.LookupItem> {
  final i0.Value<String> lookupName;
  final i0.Value<String> id;
  final i0.Value<String> payload;
  final i0.Value<DateTime> cachedAt;
  final i0.Value<int> version;
  final i0.Value<int> rowid;
  const LookupItemsCompanion({
    this.lookupName = const i0.Value.absent(),
    this.id = const i0.Value.absent(),
    this.payload = const i0.Value.absent(),
    this.cachedAt = const i0.Value.absent(),
    this.version = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  LookupItemsCompanion.insert({
    required String lookupName,
    required String id,
    required String payload,
    required DateTime cachedAt,
    required int version,
    this.rowid = const i0.Value.absent(),
  }) : lookupName = i0.Value(lookupName),
       id = i0.Value(id),
       payload = i0.Value(payload),
       cachedAt = i0.Value(cachedAt),
       version = i0.Value(version);
  static i0.Insertable<i1.LookupItem> custom({
    i0.Expression<String>? lookupName,
    i0.Expression<String>? id,
    i0.Expression<String>? payload,
    i0.Expression<DateTime>? cachedAt,
    i0.Expression<int>? version,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (lookupName != null) 'lookup_name': lookupName,
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.LookupItemsCompanion copyWith({
    i0.Value<String>? lookupName,
    i0.Value<String>? id,
    i0.Value<String>? payload,
    i0.Value<DateTime>? cachedAt,
    i0.Value<int>? version,
    i0.Value<int>? rowid,
  }) {
    return i1.LookupItemsCompanion(
      lookupName: lookupName ?? this.lookupName,
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
    if (lookupName.present) {
      map['lookup_name'] = i0.Variable<String>(lookupName.value);
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
    return (StringBuffer('LookupItemsCompanion(')
          ..write('lookupName: $lookupName, ')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

i0.Index get lookupRequestsLookupNameIdx => i0.Index(
  'lookup_requests_lookupName_idx',
  'CREATE INDEX lookup_requests_lookupName_idx ON lookup_requests (lookup_name)',
);

class $LookupRequestsTable extends i2.LookupRequests
    with i0.TableInfo<$LookupRequestsTable, i1.LookupRequest> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LookupRequestsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<String> id = i0.GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _lookupNameMeta = const i0.VerificationMeta(
    'lookupName',
  );
  @override
  late final i0.GeneratedColumn<String> lookupName = i0.GeneratedColumn<String>(
    'lookup_name',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _statusMeta = const i0.VerificationMeta(
    'status',
  );
  @override
  late final i0.GeneratedColumn<String> status = i0.GeneratedColumn<String>(
    'status',
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
    id,
    lookupName,
    status,
    payload,
    cachedAt,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lookup_requests';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.LookupRequest> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lookup_name')) {
      context.handle(
        _lookupNameMeta,
        lookupName.isAcceptableOrUnknown(data['lookup_name']!, _lookupNameMeta),
      );
    } else if (isInserting) {
      context.missing(_lookupNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
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
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.LookupRequest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.LookupRequest(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lookupName: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}lookup_name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}status'],
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
  $LookupRequestsTable createAlias(String alias) {
    return $LookupRequestsTable(attachedDatabase, alias);
  }
}

class LookupRequest extends i0.DataClass
    implements i0.Insertable<i1.LookupRequest> {
  final String id;
  final String lookupName;
  final String status;
  final String payload;
  final DateTime cachedAt;
  final int version;
  const LookupRequest({
    required this.id,
    required this.lookupName,
    required this.status,
    required this.payload,
    required this.cachedAt,
    required this.version,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<String>(id);
    map['lookup_name'] = i0.Variable<String>(lookupName);
    map['status'] = i0.Variable<String>(status);
    map['payload'] = i0.Variable<String>(payload);
    map['cached_at'] = i0.Variable<DateTime>(cachedAt);
    map['version'] = i0.Variable<int>(version);
    return map;
  }

  i1.LookupRequestsCompanion toCompanion(bool nullToAbsent) {
    return i1.LookupRequestsCompanion(
      id: i0.Value(id),
      lookupName: i0.Value(lookupName),
      status: i0.Value(status),
      payload: i0.Value(payload),
      cachedAt: i0.Value(cachedAt),
      version: i0.Value(version),
    );
  }

  factory LookupRequest.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return LookupRequest(
      id: serializer.fromJson<String>(json['id']),
      lookupName: serializer.fromJson<String>(json['lookupName']),
      status: serializer.fromJson<String>(json['status']),
      payload: serializer.fromJson<String>(json['payload']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lookupName': serializer.toJson<String>(lookupName),
      'status': serializer.toJson<String>(status),
      'payload': serializer.toJson<String>(payload),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'version': serializer.toJson<int>(version),
    };
  }

  i1.LookupRequest copyWith({
    String? id,
    String? lookupName,
    String? status,
    String? payload,
    DateTime? cachedAt,
    int? version,
  }) => i1.LookupRequest(
    id: id ?? this.id,
    lookupName: lookupName ?? this.lookupName,
    status: status ?? this.status,
    payload: payload ?? this.payload,
    cachedAt: cachedAt ?? this.cachedAt,
    version: version ?? this.version,
  );
  LookupRequest copyWithCompanion(i1.LookupRequestsCompanion data) {
    return LookupRequest(
      id: data.id.present ? data.id.value : this.id,
      lookupName: data.lookupName.present
          ? data.lookupName.value
          : this.lookupName,
      status: data.status.present ? data.status.value : this.status,
      payload: data.payload.present ? data.payload.value : this.payload,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LookupRequest(')
          ..write('id: $id, ')
          ..write('lookupName: $lookupName, ')
          ..write('status: $status, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, lookupName, status, payload, cachedAt, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.LookupRequest &&
          other.id == this.id &&
          other.lookupName == this.lookupName &&
          other.status == this.status &&
          other.payload == this.payload &&
          other.cachedAt == this.cachedAt &&
          other.version == this.version);
}

class LookupRequestsCompanion extends i0.UpdateCompanion<i1.LookupRequest> {
  final i0.Value<String> id;
  final i0.Value<String> lookupName;
  final i0.Value<String> status;
  final i0.Value<String> payload;
  final i0.Value<DateTime> cachedAt;
  final i0.Value<int> version;
  final i0.Value<int> rowid;
  const LookupRequestsCompanion({
    this.id = const i0.Value.absent(),
    this.lookupName = const i0.Value.absent(),
    this.status = const i0.Value.absent(),
    this.payload = const i0.Value.absent(),
    this.cachedAt = const i0.Value.absent(),
    this.version = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  LookupRequestsCompanion.insert({
    required String id,
    required String lookupName,
    required String status,
    required String payload,
    required DateTime cachedAt,
    required int version,
    this.rowid = const i0.Value.absent(),
  }) : id = i0.Value(id),
       lookupName = i0.Value(lookupName),
       status = i0.Value(status),
       payload = i0.Value(payload),
       cachedAt = i0.Value(cachedAt),
       version = i0.Value(version);
  static i0.Insertable<i1.LookupRequest> custom({
    i0.Expression<String>? id,
    i0.Expression<String>? lookupName,
    i0.Expression<String>? status,
    i0.Expression<String>? payload,
    i0.Expression<DateTime>? cachedAt,
    i0.Expression<int>? version,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (lookupName != null) 'lookup_name': lookupName,
      if (status != null) 'status': status,
      if (payload != null) 'payload': payload,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.LookupRequestsCompanion copyWith({
    i0.Value<String>? id,
    i0.Value<String>? lookupName,
    i0.Value<String>? status,
    i0.Value<String>? payload,
    i0.Value<DateTime>? cachedAt,
    i0.Value<int>? version,
    i0.Value<int>? rowid,
  }) {
    return i1.LookupRequestsCompanion(
      id: id ?? this.id,
      lookupName: lookupName ?? this.lookupName,
      status: status ?? this.status,
      payload: payload ?? this.payload,
      cachedAt: cachedAt ?? this.cachedAt,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<String>(id.value);
    }
    if (lookupName.present) {
      map['lookup_name'] = i0.Variable<String>(lookupName.value);
    }
    if (status.present) {
      map['status'] = i0.Variable<String>(status.value);
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
    return (StringBuffer('LookupRequestsCompanion(')
          ..write('id: $id, ')
          ..write('lookupName: $lookupName, ')
          ..write('status: $status, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

i0.Index get lookupRequestsStatusIdx => i0.Index(
  'lookup_requests_status_idx',
  'CREATE INDEX lookup_requests_status_idx ON lookup_requests (status)',
);
