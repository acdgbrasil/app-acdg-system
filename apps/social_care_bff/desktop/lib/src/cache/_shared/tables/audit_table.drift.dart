// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:social_care_desktop/src/cache/_shared/tables/audit_table.drift.dart'
    as i1;
import 'package:social_care_desktop/src/cache/_shared/tables/audit_table.dart'
    as i2;

typedef $$AuditEntriesTableCreateCompanionBuilder =
    i1.AuditEntriesCompanion Function({
      required String id,
      required String patientId,
      required String eventType,
      required String payload,
      required DateTime cachedAt,
      required int version,
      i0.Value<int> rowid,
    });
typedef $$AuditEntriesTableUpdateCompanionBuilder =
    i1.AuditEntriesCompanion Function({
      i0.Value<String> id,
      i0.Value<String> patientId,
      i0.Value<String> eventType,
      i0.Value<String> payload,
      i0.Value<DateTime> cachedAt,
      i0.Value<int> version,
      i0.Value<int> rowid,
    });

class $$AuditEntriesTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$AuditEntriesTable> {
  $$AuditEntriesTableFilterComposer({
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

  i0.ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
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

class $$AuditEntriesTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$AuditEntriesTable> {
  $$AuditEntriesTableOrderingComposer({
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

  i0.ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
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

class $$AuditEntriesTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$AuditEntriesTable> {
  $$AuditEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  i0.GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  i0.GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$AuditEntriesTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$AuditEntriesTable,
          i1.AuditEntry,
          i1.$$AuditEntriesTableFilterComposer,
          i1.$$AuditEntriesTableOrderingComposer,
          i1.$$AuditEntriesTableAnnotationComposer,
          $$AuditEntriesTableCreateCompanionBuilder,
          $$AuditEntriesTableUpdateCompanionBuilder,
          (
            i1.AuditEntry,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$AuditEntriesTable,
              i1.AuditEntry
            >,
          ),
          i1.AuditEntry,
          i0.PrefetchHooks Function()
        > {
  $$AuditEntriesTableTableManager(
    i0.GeneratedDatabase db,
    i1.$AuditEntriesTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$AuditEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$AuditEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$AuditEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> patientId = const i0.Value.absent(),
                i0.Value<String> eventType = const i0.Value.absent(),
                i0.Value<String> payload = const i0.Value.absent(),
                i0.Value<DateTime> cachedAt = const i0.Value.absent(),
                i0.Value<int> version = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.AuditEntriesCompanion(
                id: id,
                patientId: patientId,
                eventType: eventType,
                payload: payload,
                cachedAt: cachedAt,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String patientId,
                required String eventType,
                required String payload,
                required DateTime cachedAt,
                required int version,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.AuditEntriesCompanion.insert(
                id: id,
                patientId: patientId,
                eventType: eventType,
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

typedef $$AuditEntriesTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$AuditEntriesTable,
      i1.AuditEntry,
      i1.$$AuditEntriesTableFilterComposer,
      i1.$$AuditEntriesTableOrderingComposer,
      i1.$$AuditEntriesTableAnnotationComposer,
      $$AuditEntriesTableCreateCompanionBuilder,
      $$AuditEntriesTableUpdateCompanionBuilder,
      (
        i1.AuditEntry,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$AuditEntriesTable,
          i1.AuditEntry
        >,
      ),
      i1.AuditEntry,
      i0.PrefetchHooks Function()
    >;
i0.Index get auditEntriesPatientIdIdx => i0.Index(
  'audit_entries_patientId_idx',
  'CREATE INDEX audit_entries_patientId_idx ON audit_entries (patient_id)',
);

class $AuditEntriesTable extends i2.AuditEntries
    with i0.TableInfo<$AuditEntriesTable, i1.AuditEntry> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditEntriesTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<String> id = i0.GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const i0.VerificationMeta _eventTypeMeta = const i0.VerificationMeta(
    'eventType',
  );
  @override
  late final i0.GeneratedColumn<String> eventType = i0.GeneratedColumn<String>(
    'event_type',
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
    patientId,
    eventType,
    payload,
    cachedAt,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_entries';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.AuditEntry> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
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
  i1.AuditEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.AuditEntry(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}event_type'],
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
  $AuditEntriesTable createAlias(String alias) {
    return $AuditEntriesTable(attachedDatabase, alias);
  }
}

class AuditEntry extends i0.DataClass implements i0.Insertable<i1.AuditEntry> {
  final String id;
  final String patientId;
  final String eventType;
  final String payload;
  final DateTime cachedAt;
  final int version;
  const AuditEntry({
    required this.id,
    required this.patientId,
    required this.eventType,
    required this.payload,
    required this.cachedAt,
    required this.version,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<String>(id);
    map['patient_id'] = i0.Variable<String>(patientId);
    map['event_type'] = i0.Variable<String>(eventType);
    map['payload'] = i0.Variable<String>(payload);
    map['cached_at'] = i0.Variable<DateTime>(cachedAt);
    map['version'] = i0.Variable<int>(version);
    return map;
  }

  i1.AuditEntriesCompanion toCompanion(bool nullToAbsent) {
    return i1.AuditEntriesCompanion(
      id: i0.Value(id),
      patientId: i0.Value(patientId),
      eventType: i0.Value(eventType),
      payload: i0.Value(payload),
      cachedAt: i0.Value(cachedAt),
      version: i0.Value(version),
    );
  }

  factory AuditEntry.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return AuditEntry(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      eventType: serializer.fromJson<String>(json['eventType']),
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
      'patientId': serializer.toJson<String>(patientId),
      'eventType': serializer.toJson<String>(eventType),
      'payload': serializer.toJson<String>(payload),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'version': serializer.toJson<int>(version),
    };
  }

  i1.AuditEntry copyWith({
    String? id,
    String? patientId,
    String? eventType,
    String? payload,
    DateTime? cachedAt,
    int? version,
  }) => i1.AuditEntry(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    eventType: eventType ?? this.eventType,
    payload: payload ?? this.payload,
    cachedAt: cachedAt ?? this.cachedAt,
    version: version ?? this.version,
  );
  AuditEntry copyWithCompanion(i1.AuditEntriesCompanion data) {
    return AuditEntry(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      payload: data.payload.present ? data.payload.value : this.payload,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditEntry(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('eventType: $eventType, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, patientId, eventType, payload, cachedAt, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.AuditEntry &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.eventType == this.eventType &&
          other.payload == this.payload &&
          other.cachedAt == this.cachedAt &&
          other.version == this.version);
}

class AuditEntriesCompanion extends i0.UpdateCompanion<i1.AuditEntry> {
  final i0.Value<String> id;
  final i0.Value<String> patientId;
  final i0.Value<String> eventType;
  final i0.Value<String> payload;
  final i0.Value<DateTime> cachedAt;
  final i0.Value<int> version;
  final i0.Value<int> rowid;
  const AuditEntriesCompanion({
    this.id = const i0.Value.absent(),
    this.patientId = const i0.Value.absent(),
    this.eventType = const i0.Value.absent(),
    this.payload = const i0.Value.absent(),
    this.cachedAt = const i0.Value.absent(),
    this.version = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  AuditEntriesCompanion.insert({
    required String id,
    required String patientId,
    required String eventType,
    required String payload,
    required DateTime cachedAt,
    required int version,
    this.rowid = const i0.Value.absent(),
  }) : id = i0.Value(id),
       patientId = i0.Value(patientId),
       eventType = i0.Value(eventType),
       payload = i0.Value(payload),
       cachedAt = i0.Value(cachedAt),
       version = i0.Value(version);
  static i0.Insertable<i1.AuditEntry> custom({
    i0.Expression<String>? id,
    i0.Expression<String>? patientId,
    i0.Expression<String>? eventType,
    i0.Expression<String>? payload,
    i0.Expression<DateTime>? cachedAt,
    i0.Expression<int>? version,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (eventType != null) 'event_type': eventType,
      if (payload != null) 'payload': payload,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.AuditEntriesCompanion copyWith({
    i0.Value<String>? id,
    i0.Value<String>? patientId,
    i0.Value<String>? eventType,
    i0.Value<String>? payload,
    i0.Value<DateTime>? cachedAt,
    i0.Value<int>? version,
    i0.Value<int>? rowid,
  }) {
    return i1.AuditEntriesCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      eventType: eventType ?? this.eventType,
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
    if (patientId.present) {
      map['patient_id'] = i0.Variable<String>(patientId.value);
    }
    if (eventType.present) {
      map['event_type'] = i0.Variable<String>(eventType.value);
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
    return (StringBuffer('AuditEntriesCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('eventType: $eventType, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

i0.Index get auditEntriesEventTypeIdx => i0.Index(
  'audit_entries_eventType_idx',
  'CREATE INDEX audit_entries_eventType_idx ON audit_entries (event_type)',
);
