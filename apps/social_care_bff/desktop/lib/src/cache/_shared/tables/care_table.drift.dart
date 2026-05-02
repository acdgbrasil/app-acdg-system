// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:social_care_desktop/src/cache/_shared/tables/care_table.drift.dart'
    as i1;
import 'package:social_care_desktop/src/cache/_shared/tables/care_table.dart'
    as i2;

typedef $$AppointmentsTableCreateCompanionBuilder =
    i1.AppointmentsCompanion Function({
      required String patientId,
      required String id,
      required String payload,
      required DateTime cachedAt,
      required int version,
      i0.Value<int> rowid,
    });
typedef $$AppointmentsTableUpdateCompanionBuilder =
    i1.AppointmentsCompanion Function({
      i0.Value<String> patientId,
      i0.Value<String> id,
      i0.Value<String> payload,
      i0.Value<DateTime> cachedAt,
      i0.Value<int> version,
      i0.Value<int> rowid,
    });

class $$AppointmentsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$AppointmentsTable> {
  $$AppointmentsTableFilterComposer({
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

class $$AppointmentsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$AppointmentsTable> {
  $$AppointmentsTableOrderingComposer({
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

class $$AppointmentsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$AppointmentsTable> {
  $$AppointmentsTableAnnotationComposer({
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

class $$AppointmentsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$AppointmentsTable,
          i1.Appointment,
          i1.$$AppointmentsTableFilterComposer,
          i1.$$AppointmentsTableOrderingComposer,
          i1.$$AppointmentsTableAnnotationComposer,
          $$AppointmentsTableCreateCompanionBuilder,
          $$AppointmentsTableUpdateCompanionBuilder,
          (
            i1.Appointment,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$AppointmentsTable,
              i1.Appointment
            >,
          ),
          i1.Appointment,
          i0.PrefetchHooks Function()
        > {
  $$AppointmentsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$AppointmentsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$AppointmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$AppointmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$AppointmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> patientId = const i0.Value.absent(),
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> payload = const i0.Value.absent(),
                i0.Value<DateTime> cachedAt = const i0.Value.absent(),
                i0.Value<int> version = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.AppointmentsCompanion(
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
              }) => i1.AppointmentsCompanion.insert(
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

typedef $$AppointmentsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$AppointmentsTable,
      i1.Appointment,
      i1.$$AppointmentsTableFilterComposer,
      i1.$$AppointmentsTableOrderingComposer,
      i1.$$AppointmentsTableAnnotationComposer,
      $$AppointmentsTableCreateCompanionBuilder,
      $$AppointmentsTableUpdateCompanionBuilder,
      (
        i1.Appointment,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$AppointmentsTable,
          i1.Appointment
        >,
      ),
      i1.Appointment,
      i0.PrefetchHooks Function()
    >;
i0.Index get appointmentsPatientIdIdx => i0.Index(
  'appointments_patientId_idx',
  'CREATE INDEX appointments_patientId_idx ON appointments (patient_id)',
);

class $AppointmentsTable extends i2.Appointments
    with i0.TableInfo<$AppointmentsTable, i1.Appointment> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppointmentsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'appointments';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.Appointment> instance, {
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
  i1.Appointment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Appointment(
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
  $AppointmentsTable createAlias(String alias) {
    return $AppointmentsTable(attachedDatabase, alias);
  }
}

class Appointment extends i0.DataClass
    implements i0.Insertable<i1.Appointment> {
  final String patientId;
  final String id;
  final String payload;
  final DateTime cachedAt;
  final int version;
  const Appointment({
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

  i1.AppointmentsCompanion toCompanion(bool nullToAbsent) {
    return i1.AppointmentsCompanion(
      patientId: i0.Value(patientId),
      id: i0.Value(id),
      payload: i0.Value(payload),
      cachedAt: i0.Value(cachedAt),
      version: i0.Value(version),
    );
  }

  factory Appointment.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return Appointment(
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

  i1.Appointment copyWith({
    String? patientId,
    String? id,
    String? payload,
    DateTime? cachedAt,
    int? version,
  }) => i1.Appointment(
    patientId: patientId ?? this.patientId,
    id: id ?? this.id,
    payload: payload ?? this.payload,
    cachedAt: cachedAt ?? this.cachedAt,
    version: version ?? this.version,
  );
  Appointment copyWithCompanion(i1.AppointmentsCompanion data) {
    return Appointment(
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Appointment(')
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
      (other is i1.Appointment &&
          other.patientId == this.patientId &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.cachedAt == this.cachedAt &&
          other.version == this.version);
}

class AppointmentsCompanion extends i0.UpdateCompanion<i1.Appointment> {
  final i0.Value<String> patientId;
  final i0.Value<String> id;
  final i0.Value<String> payload;
  final i0.Value<DateTime> cachedAt;
  final i0.Value<int> version;
  final i0.Value<int> rowid;
  const AppointmentsCompanion({
    this.patientId = const i0.Value.absent(),
    this.id = const i0.Value.absent(),
    this.payload = const i0.Value.absent(),
    this.cachedAt = const i0.Value.absent(),
    this.version = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  AppointmentsCompanion.insert({
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
  static i0.Insertable<i1.Appointment> custom({
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

  i1.AppointmentsCompanion copyWith({
    i0.Value<String>? patientId,
    i0.Value<String>? id,
    i0.Value<String>? payload,
    i0.Value<DateTime>? cachedAt,
    i0.Value<int>? version,
    i0.Value<int>? rowid,
  }) {
    return i1.AppointmentsCompanion(
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
    return (StringBuffer('AppointmentsCompanion(')
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
