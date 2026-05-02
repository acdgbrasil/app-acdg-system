// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:persistence/src/tables/cached_lookups.drift.dart' as i1;
import 'package:persistence/src/tables/cached_lookups.dart' as i2;

typedef $$CachedLookupsTableCreateCompanionBuilder =
    i1.CachedLookupsCompanion Function({
      i0.Value<int> id,
      required String lookupName,
      required String itemsJson,
      required DateTime lastFetchedAt,
    });
typedef $$CachedLookupsTableUpdateCompanionBuilder =
    i1.CachedLookupsCompanion Function({
      i0.Value<int> id,
      i0.Value<String> lookupName,
      i0.Value<String> itemsJson,
      i0.Value<DateTime> lastFetchedAt,
    });

class $$CachedLookupsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$CachedLookupsTable> {
  $$CachedLookupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get lookupName => $composableBuilder(
    column: $table.lookupName,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$CachedLookupsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$CachedLookupsTable> {
  $$CachedLookupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get lookupName => $composableBuilder(
    column: $table.lookupName,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$CachedLookupsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$CachedLookupsTable> {
  $$CachedLookupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get lookupName => $composableBuilder(
    column: $table.lookupName,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get itemsJson =>
      $composableBuilder(column: $table.itemsJson, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => column,
  );
}

class $$CachedLookupsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$CachedLookupsTable,
          i1.CachedLookup,
          i1.$$CachedLookupsTableFilterComposer,
          i1.$$CachedLookupsTableOrderingComposer,
          i1.$$CachedLookupsTableAnnotationComposer,
          $$CachedLookupsTableCreateCompanionBuilder,
          $$CachedLookupsTableUpdateCompanionBuilder,
          (
            i1.CachedLookup,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$CachedLookupsTable,
              i1.CachedLookup
            >,
          ),
          i1.CachedLookup,
          i0.PrefetchHooks Function()
        > {
  $$CachedLookupsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$CachedLookupsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$CachedLookupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$CachedLookupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$CachedLookupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<String> lookupName = const i0.Value.absent(),
                i0.Value<String> itemsJson = const i0.Value.absent(),
                i0.Value<DateTime> lastFetchedAt = const i0.Value.absent(),
              }) => i1.CachedLookupsCompanion(
                id: id,
                lookupName: lookupName,
                itemsJson: itemsJson,
                lastFetchedAt: lastFetchedAt,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required String lookupName,
                required String itemsJson,
                required DateTime lastFetchedAt,
              }) => i1.CachedLookupsCompanion.insert(
                id: id,
                lookupName: lookupName,
                itemsJson: itemsJson,
                lastFetchedAt: lastFetchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedLookupsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$CachedLookupsTable,
      i1.CachedLookup,
      i1.$$CachedLookupsTableFilterComposer,
      i1.$$CachedLookupsTableOrderingComposer,
      i1.$$CachedLookupsTableAnnotationComposer,
      $$CachedLookupsTableCreateCompanionBuilder,
      $$CachedLookupsTableUpdateCompanionBuilder,
      (
        i1.CachedLookup,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$CachedLookupsTable,
          i1.CachedLookup
        >,
      ),
      i1.CachedLookup,
      i0.PrefetchHooks Function()
    >;

class $CachedLookupsTable extends i2.CachedLookups
    with i0.TableInfo<$CachedLookupsTable, i1.CachedLookup> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedLookupsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const i0.VerificationMeta _itemsJsonMeta = const i0.VerificationMeta(
    'itemsJson',
  );
  @override
  late final i0.GeneratedColumn<String> itemsJson = i0.GeneratedColumn<String>(
    'items_json',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _lastFetchedAtMeta =
      const i0.VerificationMeta('lastFetchedAt');
  @override
  late final i0.GeneratedColumn<DateTime> lastFetchedAt =
      i0.GeneratedColumn<DateTime>(
        'last_fetched_at',
        aliasedName,
        false,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<i0.GeneratedColumn> get $columns => [
    id,
    lookupName,
    itemsJson,
    lastFetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_lookups';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.CachedLookup> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lookup_name')) {
      context.handle(
        _lookupNameMeta,
        lookupName.isAcceptableOrUnknown(data['lookup_name']!, _lookupNameMeta),
      );
    } else if (isInserting) {
      context.missing(_lookupNameMeta);
    }
    if (data.containsKey('items_json')) {
      context.handle(
        _itemsJsonMeta,
        itemsJson.isAcceptableOrUnknown(data['items_json']!, _itemsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_itemsJsonMeta);
    }
    if (data.containsKey('last_fetched_at')) {
      context.handle(
        _lastFetchedAtMeta,
        lastFetchedAt.isAcceptableOrUnknown(
          data['last_fetched_at']!,
          _lastFetchedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastFetchedAtMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.CachedLookup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.CachedLookup(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lookupName: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}lookup_name'],
      )!,
      itemsJson: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}items_json'],
      )!,
      lastFetchedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}last_fetched_at'],
      )!,
    );
  }

  @override
  $CachedLookupsTable createAlias(String alias) {
    return $CachedLookupsTable(attachedDatabase, alias);
  }
}

class CachedLookup extends i0.DataClass
    implements i0.Insertable<i1.CachedLookup> {
  final int id;

  /// Domain table name, e.g. "dominio_parentesco".
  final String lookupName;

  /// JSON array of {id, codigo, descricao} objects.
  final String itemsJson;
  final DateTime lastFetchedAt;
  const CachedLookup({
    required this.id,
    required this.lookupName,
    required this.itemsJson,
    required this.lastFetchedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['lookup_name'] = i0.Variable<String>(lookupName);
    map['items_json'] = i0.Variable<String>(itemsJson);
    map['last_fetched_at'] = i0.Variable<DateTime>(lastFetchedAt);
    return map;
  }

  i1.CachedLookupsCompanion toCompanion(bool nullToAbsent) {
    return i1.CachedLookupsCompanion(
      id: i0.Value(id),
      lookupName: i0.Value(lookupName),
      itemsJson: i0.Value(itemsJson),
      lastFetchedAt: i0.Value(lastFetchedAt),
    );
  }

  factory CachedLookup.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return CachedLookup(
      id: serializer.fromJson<int>(json['id']),
      lookupName: serializer.fromJson<String>(json['lookupName']),
      itemsJson: serializer.fromJson<String>(json['itemsJson']),
      lastFetchedAt: serializer.fromJson<DateTime>(json['lastFetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lookupName': serializer.toJson<String>(lookupName),
      'itemsJson': serializer.toJson<String>(itemsJson),
      'lastFetchedAt': serializer.toJson<DateTime>(lastFetchedAt),
    };
  }

  i1.CachedLookup copyWith({
    int? id,
    String? lookupName,
    String? itemsJson,
    DateTime? lastFetchedAt,
  }) => i1.CachedLookup(
    id: id ?? this.id,
    lookupName: lookupName ?? this.lookupName,
    itemsJson: itemsJson ?? this.itemsJson,
    lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
  );
  CachedLookup copyWithCompanion(i1.CachedLookupsCompanion data) {
    return CachedLookup(
      id: data.id.present ? data.id.value : this.id,
      lookupName: data.lookupName.present
          ? data.lookupName.value
          : this.lookupName,
      itemsJson: data.itemsJson.present ? data.itemsJson.value : this.itemsJson,
      lastFetchedAt: data.lastFetchedAt.present
          ? data.lastFetchedAt.value
          : this.lastFetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedLookup(')
          ..write('id: $id, ')
          ..write('lookupName: $lookupName, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('lastFetchedAt: $lastFetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lookupName, itemsJson, lastFetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.CachedLookup &&
          other.id == this.id &&
          other.lookupName == this.lookupName &&
          other.itemsJson == this.itemsJson &&
          other.lastFetchedAt == this.lastFetchedAt);
}

class CachedLookupsCompanion extends i0.UpdateCompanion<i1.CachedLookup> {
  final i0.Value<int> id;
  final i0.Value<String> lookupName;
  final i0.Value<String> itemsJson;
  final i0.Value<DateTime> lastFetchedAt;
  const CachedLookupsCompanion({
    this.id = const i0.Value.absent(),
    this.lookupName = const i0.Value.absent(),
    this.itemsJson = const i0.Value.absent(),
    this.lastFetchedAt = const i0.Value.absent(),
  });
  CachedLookupsCompanion.insert({
    this.id = const i0.Value.absent(),
    required String lookupName,
    required String itemsJson,
    required DateTime lastFetchedAt,
  }) : lookupName = i0.Value(lookupName),
       itemsJson = i0.Value(itemsJson),
       lastFetchedAt = i0.Value(lastFetchedAt);
  static i0.Insertable<i1.CachedLookup> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? lookupName,
    i0.Expression<String>? itemsJson,
    i0.Expression<DateTime>? lastFetchedAt,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (lookupName != null) 'lookup_name': lookupName,
      if (itemsJson != null) 'items_json': itemsJson,
      if (lastFetchedAt != null) 'last_fetched_at': lastFetchedAt,
    });
  }

  i1.CachedLookupsCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<String>? lookupName,
    i0.Value<String>? itemsJson,
    i0.Value<DateTime>? lastFetchedAt,
  }) {
    return i1.CachedLookupsCompanion(
      id: id ?? this.id,
      lookupName: lookupName ?? this.lookupName,
      itemsJson: itemsJson ?? this.itemsJson,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (lookupName.present) {
      map['lookup_name'] = i0.Variable<String>(lookupName.value);
    }
    if (itemsJson.present) {
      map['items_json'] = i0.Variable<String>(itemsJson.value);
    }
    if (lastFetchedAt.present) {
      map['last_fetched_at'] = i0.Variable<DateTime>(lastFetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedLookupsCompanion(')
          ..write('id: $id, ')
          ..write('lookupName: $lookupName, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('lastFetchedAt: $lastFetchedAt')
          ..write(')'))
        .toString();
  }
}
