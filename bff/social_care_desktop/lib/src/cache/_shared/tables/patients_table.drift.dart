// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:social_care_desktop/src/cache/_shared/tables/patients_table.drift.dart'
    as i1;
import 'package:social_care_desktop/src/cache/_shared/tables/patients_table.dart'
    as i2;

typedef $$PatientsTableCreateCompanionBuilder =
    i1.PatientsCompanion Function({
      required String id,
      required String personId,
      required String status,
      required String payload,
      required DateTime cachedAt,
      required int version,
      i0.Value<int> rowid,
    });
typedef $$PatientsTableUpdateCompanionBuilder =
    i1.PatientsCompanion Function({
      i0.Value<String> id,
      i0.Value<String> personId,
      i0.Value<String> status,
      i0.Value<String> payload,
      i0.Value<DateTime> cachedAt,
      i0.Value<int> version,
      i0.Value<int> rowid,
    });

class $$PatientsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PatientsTable> {
  $$PatientsTableFilterComposer({
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

  i0.ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
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

class $$PatientsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PatientsTable> {
  $$PatientsTableOrderingComposer({
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

  i0.ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
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

class $$PatientsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PatientsTable> {
  $$PatientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  i0.GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  i0.GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$PatientsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$PatientsTable,
          i1.Patient,
          i1.$$PatientsTableFilterComposer,
          i1.$$PatientsTableOrderingComposer,
          i1.$$PatientsTableAnnotationComposer,
          $$PatientsTableCreateCompanionBuilder,
          $$PatientsTableUpdateCompanionBuilder,
          (
            i1.Patient,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$PatientsTable,
              i1.Patient
            >,
          ),
          i1.Patient,
          i0.PrefetchHooks Function()
        > {
  $$PatientsTableTableManager(i0.GeneratedDatabase db, i1.$PatientsTable table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$PatientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$PatientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$PatientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> personId = const i0.Value.absent(),
                i0.Value<String> status = const i0.Value.absent(),
                i0.Value<String> payload = const i0.Value.absent(),
                i0.Value<DateTime> cachedAt = const i0.Value.absent(),
                i0.Value<int> version = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.PatientsCompanion(
                id: id,
                personId: personId,
                status: status,
                payload: payload,
                cachedAt: cachedAt,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String personId,
                required String status,
                required String payload,
                required DateTime cachedAt,
                required int version,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.PatientsCompanion.insert(
                id: id,
                personId: personId,
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

typedef $$PatientsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$PatientsTable,
      i1.Patient,
      i1.$$PatientsTableFilterComposer,
      i1.$$PatientsTableOrderingComposer,
      i1.$$PatientsTableAnnotationComposer,
      $$PatientsTableCreateCompanionBuilder,
      $$PatientsTableUpdateCompanionBuilder,
      (
        i1.Patient,
        i0.BaseReferences<i0.GeneratedDatabase, i1.$PatientsTable, i1.Patient>,
      ),
      i1.Patient,
      i0.PrefetchHooks Function()
    >;
typedef $$PatientSummariesTableCreateCompanionBuilder =
    i1.PatientSummariesCompanion Function({
      required String patientId,
      required String personId,
      i0.Value<String?> firstName,
      i0.Value<String?> lastName,
      i0.Value<String?> primaryDiagnosis,
      required String status,
      required String payload,
      required DateTime cachedAt,
      required int version,
      i0.Value<int> rowid,
    });
typedef $$PatientSummariesTableUpdateCompanionBuilder =
    i1.PatientSummariesCompanion Function({
      i0.Value<String> patientId,
      i0.Value<String> personId,
      i0.Value<String?> firstName,
      i0.Value<String?> lastName,
      i0.Value<String?> primaryDiagnosis,
      i0.Value<String> status,
      i0.Value<String> payload,
      i0.Value<DateTime> cachedAt,
      i0.Value<int> version,
      i0.Value<int> rowid,
    });

class $$PatientSummariesTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PatientSummariesTable> {
  $$PatientSummariesTableFilterComposer({
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

  i0.ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get primaryDiagnosis => $composableBuilder(
    column: $table.primaryDiagnosis,
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

class $$PatientSummariesTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PatientSummariesTable> {
  $$PatientSummariesTableOrderingComposer({
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

  i0.ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get primaryDiagnosis => $composableBuilder(
    column: $table.primaryDiagnosis,
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

class $$PatientSummariesTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PatientSummariesTable> {
  $$PatientSummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  i0.GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  i0.GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  i0.GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  i0.GeneratedColumn<String> get primaryDiagnosis => $composableBuilder(
    column: $table.primaryDiagnosis,
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

class $$PatientSummariesTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$PatientSummariesTable,
          i1.PatientSummary,
          i1.$$PatientSummariesTableFilterComposer,
          i1.$$PatientSummariesTableOrderingComposer,
          i1.$$PatientSummariesTableAnnotationComposer,
          $$PatientSummariesTableCreateCompanionBuilder,
          $$PatientSummariesTableUpdateCompanionBuilder,
          (
            i1.PatientSummary,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$PatientSummariesTable,
              i1.PatientSummary
            >,
          ),
          i1.PatientSummary,
          i0.PrefetchHooks Function()
        > {
  $$PatientSummariesTableTableManager(
    i0.GeneratedDatabase db,
    i1.$PatientSummariesTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$PatientSummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => i1
              .$$PatientSummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$PatientSummariesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                i0.Value<String> patientId = const i0.Value.absent(),
                i0.Value<String> personId = const i0.Value.absent(),
                i0.Value<String?> firstName = const i0.Value.absent(),
                i0.Value<String?> lastName = const i0.Value.absent(),
                i0.Value<String?> primaryDiagnosis = const i0.Value.absent(),
                i0.Value<String> status = const i0.Value.absent(),
                i0.Value<String> payload = const i0.Value.absent(),
                i0.Value<DateTime> cachedAt = const i0.Value.absent(),
                i0.Value<int> version = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.PatientSummariesCompanion(
                patientId: patientId,
                personId: personId,
                firstName: firstName,
                lastName: lastName,
                primaryDiagnosis: primaryDiagnosis,
                status: status,
                payload: payload,
                cachedAt: cachedAt,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String patientId,
                required String personId,
                i0.Value<String?> firstName = const i0.Value.absent(),
                i0.Value<String?> lastName = const i0.Value.absent(),
                i0.Value<String?> primaryDiagnosis = const i0.Value.absent(),
                required String status,
                required String payload,
                required DateTime cachedAt,
                required int version,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.PatientSummariesCompanion.insert(
                patientId: patientId,
                personId: personId,
                firstName: firstName,
                lastName: lastName,
                primaryDiagnosis: primaryDiagnosis,
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

typedef $$PatientSummariesTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$PatientSummariesTable,
      i1.PatientSummary,
      i1.$$PatientSummariesTableFilterComposer,
      i1.$$PatientSummariesTableOrderingComposer,
      i1.$$PatientSummariesTableAnnotationComposer,
      $$PatientSummariesTableCreateCompanionBuilder,
      $$PatientSummariesTableUpdateCompanionBuilder,
      (
        i1.PatientSummary,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$PatientSummariesTable,
          i1.PatientSummary
        >,
      ),
      i1.PatientSummary,
      i0.PrefetchHooks Function()
    >;
i0.Index get patientsPersonIdIdx => i0.Index(
  'patients_personId_idx',
  'CREATE INDEX patients_personId_idx ON patients (person_id)',
);

class $PatientsTable extends i2.Patients
    with i0.TableInfo<$PatientsTable, i1.Patient> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatientsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<String> id = i0.GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _personIdMeta = const i0.VerificationMeta(
    'personId',
  );
  @override
  late final i0.GeneratedColumn<String> personId = i0.GeneratedColumn<String>(
    'person_id',
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
    personId,
    status,
    payload,
    cachedAt,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patients';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.Patient> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
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
  i1.Patient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Patient(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}person_id'],
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
  $PatientsTable createAlias(String alias) {
    return $PatientsTable(attachedDatabase, alias);
  }
}

class Patient extends i0.DataClass implements i0.Insertable<i1.Patient> {
  final String id;
  final String personId;
  final String status;
  final String payload;
  final DateTime cachedAt;
  final int version;
  const Patient({
    required this.id,
    required this.personId,
    required this.status,
    required this.payload,
    required this.cachedAt,
    required this.version,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<String>(id);
    map['person_id'] = i0.Variable<String>(personId);
    map['status'] = i0.Variable<String>(status);
    map['payload'] = i0.Variable<String>(payload);
    map['cached_at'] = i0.Variable<DateTime>(cachedAt);
    map['version'] = i0.Variable<int>(version);
    return map;
  }

  i1.PatientsCompanion toCompanion(bool nullToAbsent) {
    return i1.PatientsCompanion(
      id: i0.Value(id),
      personId: i0.Value(personId),
      status: i0.Value(status),
      payload: i0.Value(payload),
      cachedAt: i0.Value(cachedAt),
      version: i0.Value(version),
    );
  }

  factory Patient.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return Patient(
      id: serializer.fromJson<String>(json['id']),
      personId: serializer.fromJson<String>(json['personId']),
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
      'personId': serializer.toJson<String>(personId),
      'status': serializer.toJson<String>(status),
      'payload': serializer.toJson<String>(payload),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'version': serializer.toJson<int>(version),
    };
  }

  i1.Patient copyWith({
    String? id,
    String? personId,
    String? status,
    String? payload,
    DateTime? cachedAt,
    int? version,
  }) => i1.Patient(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    status: status ?? this.status,
    payload: payload ?? this.payload,
    cachedAt: cachedAt ?? this.cachedAt,
    version: version ?? this.version,
  );
  Patient copyWithCompanion(i1.PatientsCompanion data) {
    return Patient(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      status: data.status.present ? data.status.value : this.status,
      payload: data.payload.present ? data.payload.value : this.payload,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Patient(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('status: $status, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, personId, status, payload, cachedAt, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.Patient &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.status == this.status &&
          other.payload == this.payload &&
          other.cachedAt == this.cachedAt &&
          other.version == this.version);
}

class PatientsCompanion extends i0.UpdateCompanion<i1.Patient> {
  final i0.Value<String> id;
  final i0.Value<String> personId;
  final i0.Value<String> status;
  final i0.Value<String> payload;
  final i0.Value<DateTime> cachedAt;
  final i0.Value<int> version;
  final i0.Value<int> rowid;
  const PatientsCompanion({
    this.id = const i0.Value.absent(),
    this.personId = const i0.Value.absent(),
    this.status = const i0.Value.absent(),
    this.payload = const i0.Value.absent(),
    this.cachedAt = const i0.Value.absent(),
    this.version = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  PatientsCompanion.insert({
    required String id,
    required String personId,
    required String status,
    required String payload,
    required DateTime cachedAt,
    required int version,
    this.rowid = const i0.Value.absent(),
  }) : id = i0.Value(id),
       personId = i0.Value(personId),
       status = i0.Value(status),
       payload = i0.Value(payload),
       cachedAt = i0.Value(cachedAt),
       version = i0.Value(version);
  static i0.Insertable<i1.Patient> custom({
    i0.Expression<String>? id,
    i0.Expression<String>? personId,
    i0.Expression<String>? status,
    i0.Expression<String>? payload,
    i0.Expression<DateTime>? cachedAt,
    i0.Expression<int>? version,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (status != null) 'status': status,
      if (payload != null) 'payload': payload,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.PatientsCompanion copyWith({
    i0.Value<String>? id,
    i0.Value<String>? personId,
    i0.Value<String>? status,
    i0.Value<String>? payload,
    i0.Value<DateTime>? cachedAt,
    i0.Value<int>? version,
    i0.Value<int>? rowid,
  }) {
    return i1.PatientsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
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
    if (personId.present) {
      map['person_id'] = i0.Variable<String>(personId.value);
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
    return (StringBuffer('PatientsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('status: $status, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

i0.Index get patientsStatusIdx => i0.Index(
  'patients_status_idx',
  'CREATE INDEX patients_status_idx ON patients (status)',
);
i0.Index get patientSummariesStatusIdx => i0.Index(
  'patient_summaries_status_idx',
  'CREATE INDEX patient_summaries_status_idx ON patient_summaries (status)',
);

class $PatientSummariesTable extends i2.PatientSummaries
    with i0.TableInfo<$PatientSummariesTable, i1.PatientSummary> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatientSummariesTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _personIdMeta = const i0.VerificationMeta(
    'personId',
  );
  @override
  late final i0.GeneratedColumn<String> personId = i0.GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _firstNameMeta = const i0.VerificationMeta(
    'firstName',
  );
  @override
  late final i0.GeneratedColumn<String> firstName = i0.GeneratedColumn<String>(
    'first_name',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _lastNameMeta = const i0.VerificationMeta(
    'lastName',
  );
  @override
  late final i0.GeneratedColumn<String> lastName = i0.GeneratedColumn<String>(
    'last_name',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _primaryDiagnosisMeta =
      const i0.VerificationMeta('primaryDiagnosis');
  @override
  late final i0.GeneratedColumn<String> primaryDiagnosis =
      i0.GeneratedColumn<String>(
        'primary_diagnosis',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
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
    patientId,
    personId,
    firstName,
    lastName,
    primaryDiagnosis,
    status,
    payload,
    cachedAt,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patient_summaries';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.PatientSummary> instance, {
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
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    }
    if (data.containsKey('primary_diagnosis')) {
      context.handle(
        _primaryDiagnosisMeta,
        primaryDiagnosis.isAcceptableOrUnknown(
          data['primary_diagnosis']!,
          _primaryDiagnosisMeta,
        ),
      );
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
  Set<i0.GeneratedColumn> get $primaryKey => {patientId};
  @override
  i1.PatientSummary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.PatientSummary(
      patientId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      ),
      lastName: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      ),
      primaryDiagnosis: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}primary_diagnosis'],
      ),
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
  $PatientSummariesTable createAlias(String alias) {
    return $PatientSummariesTable(attachedDatabase, alias);
  }
}

class PatientSummary extends i0.DataClass
    implements i0.Insertable<i1.PatientSummary> {
  final String patientId;
  final String personId;
  final String? firstName;
  final String? lastName;
  final String? primaryDiagnosis;
  final String status;
  final String payload;
  final DateTime cachedAt;
  final int version;
  const PatientSummary({
    required this.patientId,
    required this.personId,
    this.firstName,
    this.lastName,
    this.primaryDiagnosis,
    required this.status,
    required this.payload,
    required this.cachedAt,
    required this.version,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['patient_id'] = i0.Variable<String>(patientId);
    map['person_id'] = i0.Variable<String>(personId);
    if (!nullToAbsent || firstName != null) {
      map['first_name'] = i0.Variable<String>(firstName);
    }
    if (!nullToAbsent || lastName != null) {
      map['last_name'] = i0.Variable<String>(lastName);
    }
    if (!nullToAbsent || primaryDiagnosis != null) {
      map['primary_diagnosis'] = i0.Variable<String>(primaryDiagnosis);
    }
    map['status'] = i0.Variable<String>(status);
    map['payload'] = i0.Variable<String>(payload);
    map['cached_at'] = i0.Variable<DateTime>(cachedAt);
    map['version'] = i0.Variable<int>(version);
    return map;
  }

  i1.PatientSummariesCompanion toCompanion(bool nullToAbsent) {
    return i1.PatientSummariesCompanion(
      patientId: i0.Value(patientId),
      personId: i0.Value(personId),
      firstName: firstName == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(firstName),
      lastName: lastName == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(lastName),
      primaryDiagnosis: primaryDiagnosis == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(primaryDiagnosis),
      status: i0.Value(status),
      payload: i0.Value(payload),
      cachedAt: i0.Value(cachedAt),
      version: i0.Value(version),
    );
  }

  factory PatientSummary.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return PatientSummary(
      patientId: serializer.fromJson<String>(json['patientId']),
      personId: serializer.fromJson<String>(json['personId']),
      firstName: serializer.fromJson<String?>(json['firstName']),
      lastName: serializer.fromJson<String?>(json['lastName']),
      primaryDiagnosis: serializer.fromJson<String?>(json['primaryDiagnosis']),
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
      'patientId': serializer.toJson<String>(patientId),
      'personId': serializer.toJson<String>(personId),
      'firstName': serializer.toJson<String?>(firstName),
      'lastName': serializer.toJson<String?>(lastName),
      'primaryDiagnosis': serializer.toJson<String?>(primaryDiagnosis),
      'status': serializer.toJson<String>(status),
      'payload': serializer.toJson<String>(payload),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'version': serializer.toJson<int>(version),
    };
  }

  i1.PatientSummary copyWith({
    String? patientId,
    String? personId,
    i0.Value<String?> firstName = const i0.Value.absent(),
    i0.Value<String?> lastName = const i0.Value.absent(),
    i0.Value<String?> primaryDiagnosis = const i0.Value.absent(),
    String? status,
    String? payload,
    DateTime? cachedAt,
    int? version,
  }) => i1.PatientSummary(
    patientId: patientId ?? this.patientId,
    personId: personId ?? this.personId,
    firstName: firstName.present ? firstName.value : this.firstName,
    lastName: lastName.present ? lastName.value : this.lastName,
    primaryDiagnosis: primaryDiagnosis.present
        ? primaryDiagnosis.value
        : this.primaryDiagnosis,
    status: status ?? this.status,
    payload: payload ?? this.payload,
    cachedAt: cachedAt ?? this.cachedAt,
    version: version ?? this.version,
  );
  PatientSummary copyWithCompanion(i1.PatientSummariesCompanion data) {
    return PatientSummary(
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      personId: data.personId.present ? data.personId.value : this.personId,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      primaryDiagnosis: data.primaryDiagnosis.present
          ? data.primaryDiagnosis.value
          : this.primaryDiagnosis,
      status: data.status.present ? data.status.value : this.status,
      payload: data.payload.present ? data.payload.value : this.payload,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PatientSummary(')
          ..write('patientId: $patientId, ')
          ..write('personId: $personId, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('primaryDiagnosis: $primaryDiagnosis, ')
          ..write('status: $status, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    patientId,
    personId,
    firstName,
    lastName,
    primaryDiagnosis,
    status,
    payload,
    cachedAt,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.PatientSummary &&
          other.patientId == this.patientId &&
          other.personId == this.personId &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.primaryDiagnosis == this.primaryDiagnosis &&
          other.status == this.status &&
          other.payload == this.payload &&
          other.cachedAt == this.cachedAt &&
          other.version == this.version);
}

class PatientSummariesCompanion extends i0.UpdateCompanion<i1.PatientSummary> {
  final i0.Value<String> patientId;
  final i0.Value<String> personId;
  final i0.Value<String?> firstName;
  final i0.Value<String?> lastName;
  final i0.Value<String?> primaryDiagnosis;
  final i0.Value<String> status;
  final i0.Value<String> payload;
  final i0.Value<DateTime> cachedAt;
  final i0.Value<int> version;
  final i0.Value<int> rowid;
  const PatientSummariesCompanion({
    this.patientId = const i0.Value.absent(),
    this.personId = const i0.Value.absent(),
    this.firstName = const i0.Value.absent(),
    this.lastName = const i0.Value.absent(),
    this.primaryDiagnosis = const i0.Value.absent(),
    this.status = const i0.Value.absent(),
    this.payload = const i0.Value.absent(),
    this.cachedAt = const i0.Value.absent(),
    this.version = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  PatientSummariesCompanion.insert({
    required String patientId,
    required String personId,
    this.firstName = const i0.Value.absent(),
    this.lastName = const i0.Value.absent(),
    this.primaryDiagnosis = const i0.Value.absent(),
    required String status,
    required String payload,
    required DateTime cachedAt,
    required int version,
    this.rowid = const i0.Value.absent(),
  }) : patientId = i0.Value(patientId),
       personId = i0.Value(personId),
       status = i0.Value(status),
       payload = i0.Value(payload),
       cachedAt = i0.Value(cachedAt),
       version = i0.Value(version);
  static i0.Insertable<i1.PatientSummary> custom({
    i0.Expression<String>? patientId,
    i0.Expression<String>? personId,
    i0.Expression<String>? firstName,
    i0.Expression<String>? lastName,
    i0.Expression<String>? primaryDiagnosis,
    i0.Expression<String>? status,
    i0.Expression<String>? payload,
    i0.Expression<DateTime>? cachedAt,
    i0.Expression<int>? version,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (patientId != null) 'patient_id': patientId,
      if (personId != null) 'person_id': personId,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (primaryDiagnosis != null) 'primary_diagnosis': primaryDiagnosis,
      if (status != null) 'status': status,
      if (payload != null) 'payload': payload,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.PatientSummariesCompanion copyWith({
    i0.Value<String>? patientId,
    i0.Value<String>? personId,
    i0.Value<String?>? firstName,
    i0.Value<String?>? lastName,
    i0.Value<String?>? primaryDiagnosis,
    i0.Value<String>? status,
    i0.Value<String>? payload,
    i0.Value<DateTime>? cachedAt,
    i0.Value<int>? version,
    i0.Value<int>? rowid,
  }) {
    return i1.PatientSummariesCompanion(
      patientId: patientId ?? this.patientId,
      personId: personId ?? this.personId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      primaryDiagnosis: primaryDiagnosis ?? this.primaryDiagnosis,
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
    if (patientId.present) {
      map['patient_id'] = i0.Variable<String>(patientId.value);
    }
    if (personId.present) {
      map['person_id'] = i0.Variable<String>(personId.value);
    }
    if (firstName.present) {
      map['first_name'] = i0.Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = i0.Variable<String>(lastName.value);
    }
    if (primaryDiagnosis.present) {
      map['primary_diagnosis'] = i0.Variable<String>(primaryDiagnosis.value);
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
    return (StringBuffer('PatientSummariesCompanion(')
          ..write('patientId: $patientId, ')
          ..write('personId: $personId, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('primaryDiagnosis: $primaryDiagnosis, ')
          ..write('status: $status, ')
          ..write('payload: $payload, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}
