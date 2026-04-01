// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:persistence/src/tables/cached_patients.drift.dart' as i1;
import 'package:persistence/src/tables/cached_patients.dart' as i2;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i3;

typedef $$CachedPatientsTableCreateCompanionBuilder =
    i1.CachedPatientsCompanion Function({
      i0.Value<int> id,
      required String patientId,
      required String personId,
      i0.Value<String> firstName,
      i0.Value<String> lastName,
      i0.Value<String> cpf,
      required String fullRecordJson,
      i0.Value<int> version,
      i0.Value<bool> isDirty,
      required DateTime lastSyncAt,
    });
typedef $$CachedPatientsTableUpdateCompanionBuilder =
    i1.CachedPatientsCompanion Function({
      i0.Value<int> id,
      i0.Value<String> patientId,
      i0.Value<String> personId,
      i0.Value<String> firstName,
      i0.Value<String> lastName,
      i0.Value<String> cpf,
      i0.Value<String> fullRecordJson,
      i0.Value<int> version,
      i0.Value<bool> isDirty,
      i0.Value<DateTime> lastSyncAt,
    });

class $$CachedPatientsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$CachedPatientsTable> {
  $$CachedPatientsTableFilterComposer({
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

  i0.ColumnFilters<String> get cpf => $composableBuilder(
    column: $table.cpf,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get fullRecordJson => $composableBuilder(
    column: $table.fullRecordJson,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$CachedPatientsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$CachedPatientsTable> {
  $$CachedPatientsTableOrderingComposer({
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

  i0.ColumnOrderings<String> get cpf => $composableBuilder(
    column: $table.cpf,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get fullRecordJson => $composableBuilder(
    column: $table.fullRecordJson,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$CachedPatientsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$CachedPatientsTable> {
  $$CachedPatientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  i0.GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  i0.GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  i0.GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  i0.GeneratedColumn<String> get cpf =>
      $composableBuilder(column: $table.cpf, builder: (column) => column);

  i0.GeneratedColumn<String> get fullRecordJson => $composableBuilder(
    column: $table.fullRecordJson,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  i0.GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );
}

class $$CachedPatientsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$CachedPatientsTable,
          i1.CachedPatient,
          i1.$$CachedPatientsTableFilterComposer,
          i1.$$CachedPatientsTableOrderingComposer,
          i1.$$CachedPatientsTableAnnotationComposer,
          $$CachedPatientsTableCreateCompanionBuilder,
          $$CachedPatientsTableUpdateCompanionBuilder,
          (
            i1.CachedPatient,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$CachedPatientsTable,
              i1.CachedPatient
            >,
          ),
          i1.CachedPatient,
          i0.PrefetchHooks Function()
        > {
  $$CachedPatientsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$CachedPatientsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$CachedPatientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$CachedPatientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => i1
              .$$CachedPatientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<String> patientId = const i0.Value.absent(),
                i0.Value<String> personId = const i0.Value.absent(),
                i0.Value<String> firstName = const i0.Value.absent(),
                i0.Value<String> lastName = const i0.Value.absent(),
                i0.Value<String> cpf = const i0.Value.absent(),
                i0.Value<String> fullRecordJson = const i0.Value.absent(),
                i0.Value<int> version = const i0.Value.absent(),
                i0.Value<bool> isDirty = const i0.Value.absent(),
                i0.Value<DateTime> lastSyncAt = const i0.Value.absent(),
              }) => i1.CachedPatientsCompanion(
                id: id,
                patientId: patientId,
                personId: personId,
                firstName: firstName,
                lastName: lastName,
                cpf: cpf,
                fullRecordJson: fullRecordJson,
                version: version,
                isDirty: isDirty,
                lastSyncAt: lastSyncAt,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required String patientId,
                required String personId,
                i0.Value<String> firstName = const i0.Value.absent(),
                i0.Value<String> lastName = const i0.Value.absent(),
                i0.Value<String> cpf = const i0.Value.absent(),
                required String fullRecordJson,
                i0.Value<int> version = const i0.Value.absent(),
                i0.Value<bool> isDirty = const i0.Value.absent(),
                required DateTime lastSyncAt,
              }) => i1.CachedPatientsCompanion.insert(
                id: id,
                patientId: patientId,
                personId: personId,
                firstName: firstName,
                lastName: lastName,
                cpf: cpf,
                fullRecordJson: fullRecordJson,
                version: version,
                isDirty: isDirty,
                lastSyncAt: lastSyncAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPatientsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$CachedPatientsTable,
      i1.CachedPatient,
      i1.$$CachedPatientsTableFilterComposer,
      i1.$$CachedPatientsTableOrderingComposer,
      i1.$$CachedPatientsTableAnnotationComposer,
      $$CachedPatientsTableCreateCompanionBuilder,
      $$CachedPatientsTableUpdateCompanionBuilder,
      (
        i1.CachedPatient,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$CachedPatientsTable,
          i1.CachedPatient
        >,
      ),
      i1.CachedPatient,
      i0.PrefetchHooks Function()
    >;

class $CachedPatientsTable extends i2.CachedPatients
    with i0.TableInfo<$CachedPatientsTable, i1.CachedPatient> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPatientsTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways('UNIQUE'),
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
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const i3.Constant(''),
  );
  static const i0.VerificationMeta _lastNameMeta = const i0.VerificationMeta(
    'lastName',
  );
  @override
  late final i0.GeneratedColumn<String> lastName = i0.GeneratedColumn<String>(
    'last_name',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const i3.Constant(''),
  );
  static const i0.VerificationMeta _cpfMeta = const i0.VerificationMeta('cpf');
  @override
  late final i0.GeneratedColumn<String> cpf = i0.GeneratedColumn<String>(
    'cpf',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const i3.Constant(''),
  );
  static const i0.VerificationMeta _fullRecordJsonMeta =
      const i0.VerificationMeta('fullRecordJson');
  @override
  late final i0.GeneratedColumn<String> fullRecordJson =
      i0.GeneratedColumn<String>(
        'full_record_json',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
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
    requiredDuringInsert: false,
    defaultValue: const i3.Constant(1),
  );
  static const i0.VerificationMeta _isDirtyMeta = const i0.VerificationMeta(
    'isDirty',
  );
  @override
  late final i0.GeneratedColumn<bool> isDirty = i0.GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: i0.DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const i3.Constant(false),
  );
  static const i0.VerificationMeta _lastSyncAtMeta = const i0.VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final i0.GeneratedColumn<DateTime> lastSyncAt =
      i0.GeneratedColumn<DateTime>(
        'last_sync_at',
        aliasedName,
        false,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<i0.GeneratedColumn> get $columns => [
    id,
    patientId,
    personId,
    firstName,
    lastName,
    cpf,
    fullRecordJson,
    version,
    isDirty,
    lastSyncAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_patients';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.CachedPatient> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
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
    if (data.containsKey('cpf')) {
      context.handle(
        _cpfMeta,
        cpf.isAcceptableOrUnknown(data['cpf']!, _cpfMeta),
      );
    }
    if (data.containsKey('full_record_json')) {
      context.handle(
        _fullRecordJsonMeta,
        fullRecordJson.isAcceptableOrUnknown(
          data['full_record_json']!,
          _fullRecordJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fullRecordJsonMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSyncAtMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.CachedPatient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.CachedPatient(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
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
      )!,
      lastName: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      )!,
      cpf: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}cpf'],
      )!,
      fullRecordJson: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}full_record_json'],
      )!,
      version: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      )!,
    );
  }

  @override
  $CachedPatientsTable createAlias(String alias) {
    return $CachedPatientsTable(attachedDatabase, alias);
  }
}

class CachedPatient extends i0.DataClass
    implements i0.Insertable<i1.CachedPatient> {
  final int id;
  final String patientId;
  final String personId;
  final String firstName;
  final String lastName;
  final String cpf;

  /// Complete patient aggregate serialized as JSON.
  final String fullRecordJson;

  /// Server version for optimistic concurrency control.
  final int version;

  /// Whether this record has local modifications pending sync.
  final bool isDirty;
  final DateTime lastSyncAt;
  const CachedPatient({
    required this.id,
    required this.patientId,
    required this.personId,
    required this.firstName,
    required this.lastName,
    required this.cpf,
    required this.fullRecordJson,
    required this.version,
    required this.isDirty,
    required this.lastSyncAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['patient_id'] = i0.Variable<String>(patientId);
    map['person_id'] = i0.Variable<String>(personId);
    map['first_name'] = i0.Variable<String>(firstName);
    map['last_name'] = i0.Variable<String>(lastName);
    map['cpf'] = i0.Variable<String>(cpf);
    map['full_record_json'] = i0.Variable<String>(fullRecordJson);
    map['version'] = i0.Variable<int>(version);
    map['is_dirty'] = i0.Variable<bool>(isDirty);
    map['last_sync_at'] = i0.Variable<DateTime>(lastSyncAt);
    return map;
  }

  i1.CachedPatientsCompanion toCompanion(bool nullToAbsent) {
    return i1.CachedPatientsCompanion(
      id: i0.Value(id),
      patientId: i0.Value(patientId),
      personId: i0.Value(personId),
      firstName: i0.Value(firstName),
      lastName: i0.Value(lastName),
      cpf: i0.Value(cpf),
      fullRecordJson: i0.Value(fullRecordJson),
      version: i0.Value(version),
      isDirty: i0.Value(isDirty),
      lastSyncAt: i0.Value(lastSyncAt),
    );
  }

  factory CachedPatient.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return CachedPatient(
      id: serializer.fromJson<int>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      personId: serializer.fromJson<String>(json['personId']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      cpf: serializer.fromJson<String>(json['cpf']),
      fullRecordJson: serializer.fromJson<String>(json['fullRecordJson']),
      version: serializer.fromJson<int>(json['version']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      lastSyncAt: serializer.fromJson<DateTime>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'patientId': serializer.toJson<String>(patientId),
      'personId': serializer.toJson<String>(personId),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'cpf': serializer.toJson<String>(cpf),
      'fullRecordJson': serializer.toJson<String>(fullRecordJson),
      'version': serializer.toJson<int>(version),
      'isDirty': serializer.toJson<bool>(isDirty),
      'lastSyncAt': serializer.toJson<DateTime>(lastSyncAt),
    };
  }

  i1.CachedPatient copyWith({
    int? id,
    String? patientId,
    String? personId,
    String? firstName,
    String? lastName,
    String? cpf,
    String? fullRecordJson,
    int? version,
    bool? isDirty,
    DateTime? lastSyncAt,
  }) => i1.CachedPatient(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    personId: personId ?? this.personId,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    cpf: cpf ?? this.cpf,
    fullRecordJson: fullRecordJson ?? this.fullRecordJson,
    version: version ?? this.version,
    isDirty: isDirty ?? this.isDirty,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
  );
  CachedPatient copyWithCompanion(i1.CachedPatientsCompanion data) {
    return CachedPatient(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      personId: data.personId.present ? data.personId.value : this.personId,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      cpf: data.cpf.present ? data.cpf.value : this.cpf,
      fullRecordJson: data.fullRecordJson.present
          ? data.fullRecordJson.value
          : this.fullRecordJson,
      version: data.version.present ? data.version.value : this.version,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPatient(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('personId: $personId, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('cpf: $cpf, ')
          ..write('fullRecordJson: $fullRecordJson, ')
          ..write('version: $version, ')
          ..write('isDirty: $isDirty, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    personId,
    firstName,
    lastName,
    cpf,
    fullRecordJson,
    version,
    isDirty,
    lastSyncAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.CachedPatient &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.personId == this.personId &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.cpf == this.cpf &&
          other.fullRecordJson == this.fullRecordJson &&
          other.version == this.version &&
          other.isDirty == this.isDirty &&
          other.lastSyncAt == this.lastSyncAt);
}

class CachedPatientsCompanion extends i0.UpdateCompanion<i1.CachedPatient> {
  final i0.Value<int> id;
  final i0.Value<String> patientId;
  final i0.Value<String> personId;
  final i0.Value<String> firstName;
  final i0.Value<String> lastName;
  final i0.Value<String> cpf;
  final i0.Value<String> fullRecordJson;
  final i0.Value<int> version;
  final i0.Value<bool> isDirty;
  final i0.Value<DateTime> lastSyncAt;
  const CachedPatientsCompanion({
    this.id = const i0.Value.absent(),
    this.patientId = const i0.Value.absent(),
    this.personId = const i0.Value.absent(),
    this.firstName = const i0.Value.absent(),
    this.lastName = const i0.Value.absent(),
    this.cpf = const i0.Value.absent(),
    this.fullRecordJson = const i0.Value.absent(),
    this.version = const i0.Value.absent(),
    this.isDirty = const i0.Value.absent(),
    this.lastSyncAt = const i0.Value.absent(),
  });
  CachedPatientsCompanion.insert({
    this.id = const i0.Value.absent(),
    required String patientId,
    required String personId,
    this.firstName = const i0.Value.absent(),
    this.lastName = const i0.Value.absent(),
    this.cpf = const i0.Value.absent(),
    required String fullRecordJson,
    this.version = const i0.Value.absent(),
    this.isDirty = const i0.Value.absent(),
    required DateTime lastSyncAt,
  }) : patientId = i0.Value(patientId),
       personId = i0.Value(personId),
       fullRecordJson = i0.Value(fullRecordJson),
       lastSyncAt = i0.Value(lastSyncAt);
  static i0.Insertable<i1.CachedPatient> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? patientId,
    i0.Expression<String>? personId,
    i0.Expression<String>? firstName,
    i0.Expression<String>? lastName,
    i0.Expression<String>? cpf,
    i0.Expression<String>? fullRecordJson,
    i0.Expression<int>? version,
    i0.Expression<bool>? isDirty,
    i0.Expression<DateTime>? lastSyncAt,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (personId != null) 'person_id': personId,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (cpf != null) 'cpf': cpf,
      if (fullRecordJson != null) 'full_record_json': fullRecordJson,
      if (version != null) 'version': version,
      if (isDirty != null) 'is_dirty': isDirty,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
    });
  }

  i1.CachedPatientsCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<String>? patientId,
    i0.Value<String>? personId,
    i0.Value<String>? firstName,
    i0.Value<String>? lastName,
    i0.Value<String>? cpf,
    i0.Value<String>? fullRecordJson,
    i0.Value<int>? version,
    i0.Value<bool>? isDirty,
    i0.Value<DateTime>? lastSyncAt,
  }) {
    return i1.CachedPatientsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      personId: personId ?? this.personId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      cpf: cpf ?? this.cpf,
      fullRecordJson: fullRecordJson ?? this.fullRecordJson,
      version: version ?? this.version,
      isDirty: isDirty ?? this.isDirty,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
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
    if (cpf.present) {
      map['cpf'] = i0.Variable<String>(cpf.value);
    }
    if (fullRecordJson.present) {
      map['full_record_json'] = i0.Variable<String>(fullRecordJson.value);
    }
    if (version.present) {
      map['version'] = i0.Variable<int>(version.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = i0.Variable<bool>(isDirty.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = i0.Variable<DateTime>(lastSyncAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPatientsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('personId: $personId, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('cpf: $cpf, ')
          ..write('fullRecordJson: $fullRecordJson, ')
          ..write('version: $version, ')
          ..write('isDirty: $isDirty, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }
}
