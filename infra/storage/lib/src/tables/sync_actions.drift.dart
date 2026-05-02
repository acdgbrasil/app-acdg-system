// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:persistence/src/tables/sync_actions.drift.dart' as i1;
import 'package:persistence/src/tables/sync_actions.dart' as i2;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i3;

typedef $$SyncActionsTableCreateCompanionBuilder =
    i1.SyncActionsCompanion Function({
      i0.Value<int> id,
      required String actionId,
      required String patientId,
      required String actionType,
      required String payloadJson,
      required DateTime timestamp,
      i0.Value<String> status,
      i0.Value<int> retryCount,
      i0.Value<DateTime?> nextRetryAt,
      i0.Value<String?> lastError,
      i0.Value<String?> conflictDetails,
    });
typedef $$SyncActionsTableUpdateCompanionBuilder =
    i1.SyncActionsCompanion Function({
      i0.Value<int> id,
      i0.Value<String> actionId,
      i0.Value<String> patientId,
      i0.Value<String> actionType,
      i0.Value<String> payloadJson,
      i0.Value<DateTime> timestamp,
      i0.Value<String> status,
      i0.Value<int> retryCount,
      i0.Value<DateTime?> nextRetryAt,
      i0.Value<String?> lastError,
      i0.Value<String?> conflictDetails,
    });

class $$SyncActionsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$SyncActionsTable> {
  $$SyncActionsTableFilterComposer({
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

  i0.ColumnFilters<String> get actionId => $composableBuilder(
    column: $table.actionId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get conflictDetails => $composableBuilder(
    column: $table.conflictDetails,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$SyncActionsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$SyncActionsTable> {
  $$SyncActionsTableOrderingComposer({
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

  i0.ColumnOrderings<String> get actionId => $composableBuilder(
    column: $table.actionId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get conflictDetails => $composableBuilder(
    column: $table.conflictDetails,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$SyncActionsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$SyncActionsTable> {
  $$SyncActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get actionId =>
      $composableBuilder(column: $table.actionId, builder: (column) => column);

  i0.GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  i0.GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  i0.GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  i0.GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  i0.GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  i0.GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  i0.GeneratedColumn<String> get conflictDetails => $composableBuilder(
    column: $table.conflictDetails,
    builder: (column) => column,
  );
}

class $$SyncActionsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$SyncActionsTable,
          i1.SyncAction,
          i1.$$SyncActionsTableFilterComposer,
          i1.$$SyncActionsTableOrderingComposer,
          i1.$$SyncActionsTableAnnotationComposer,
          $$SyncActionsTableCreateCompanionBuilder,
          $$SyncActionsTableUpdateCompanionBuilder,
          (
            i1.SyncAction,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$SyncActionsTable,
              i1.SyncAction
            >,
          ),
          i1.SyncAction,
          i0.PrefetchHooks Function()
        > {
  $$SyncActionsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$SyncActionsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$SyncActionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$SyncActionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$SyncActionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<String> actionId = const i0.Value.absent(),
                i0.Value<String> patientId = const i0.Value.absent(),
                i0.Value<String> actionType = const i0.Value.absent(),
                i0.Value<String> payloadJson = const i0.Value.absent(),
                i0.Value<DateTime> timestamp = const i0.Value.absent(),
                i0.Value<String> status = const i0.Value.absent(),
                i0.Value<int> retryCount = const i0.Value.absent(),
                i0.Value<DateTime?> nextRetryAt = const i0.Value.absent(),
                i0.Value<String?> lastError = const i0.Value.absent(),
                i0.Value<String?> conflictDetails = const i0.Value.absent(),
              }) => i1.SyncActionsCompanion(
                id: id,
                actionId: actionId,
                patientId: patientId,
                actionType: actionType,
                payloadJson: payloadJson,
                timestamp: timestamp,
                status: status,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                lastError: lastError,
                conflictDetails: conflictDetails,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required String actionId,
                required String patientId,
                required String actionType,
                required String payloadJson,
                required DateTime timestamp,
                i0.Value<String> status = const i0.Value.absent(),
                i0.Value<int> retryCount = const i0.Value.absent(),
                i0.Value<DateTime?> nextRetryAt = const i0.Value.absent(),
                i0.Value<String?> lastError = const i0.Value.absent(),
                i0.Value<String?> conflictDetails = const i0.Value.absent(),
              }) => i1.SyncActionsCompanion.insert(
                id: id,
                actionId: actionId,
                patientId: patientId,
                actionType: actionType,
                payloadJson: payloadJson,
                timestamp: timestamp,
                status: status,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                lastError: lastError,
                conflictDetails: conflictDetails,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncActionsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$SyncActionsTable,
      i1.SyncAction,
      i1.$$SyncActionsTableFilterComposer,
      i1.$$SyncActionsTableOrderingComposer,
      i1.$$SyncActionsTableAnnotationComposer,
      $$SyncActionsTableCreateCompanionBuilder,
      $$SyncActionsTableUpdateCompanionBuilder,
      (
        i1.SyncAction,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$SyncActionsTable,
          i1.SyncAction
        >,
      ),
      i1.SyncAction,
      i0.PrefetchHooks Function()
    >;

class $SyncActionsTable extends i2.SyncActions
    with i0.TableInfo<$SyncActionsTable, i1.SyncAction> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncActionsTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _actionIdMeta = const i0.VerificationMeta(
    'actionId',
  );
  @override
  late final i0.GeneratedColumn<String> actionId = i0.GeneratedColumn<String>(
    'action_id',
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
  static const i0.VerificationMeta _actionTypeMeta = const i0.VerificationMeta(
    'actionType',
  );
  @override
  late final i0.GeneratedColumn<String> actionType = i0.GeneratedColumn<String>(
    'action_type',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _payloadJsonMeta = const i0.VerificationMeta(
    'payloadJson',
  );
  @override
  late final i0.GeneratedColumn<String> payloadJson =
      i0.GeneratedColumn<String>(
        'payload_json',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _timestampMeta = const i0.VerificationMeta(
    'timestamp',
  );
  @override
  late final i0.GeneratedColumn<DateTime> timestamp =
      i0.GeneratedColumn<DateTime>(
        'timestamp',
        aliasedName,
        false,
        type: i0.DriftSqlType.dateTime,
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
    requiredDuringInsert: false,
    defaultValue: const i3.Constant('PENDING'),
  );
  static const i0.VerificationMeta _retryCountMeta = const i0.VerificationMeta(
    'retryCount',
  );
  @override
  late final i0.GeneratedColumn<int> retryCount = i0.GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const i3.Constant(0),
  );
  static const i0.VerificationMeta _nextRetryAtMeta = const i0.VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final i0.GeneratedColumn<DateTime> nextRetryAt =
      i0.GeneratedColumn<DateTime>(
        'next_retry_at',
        aliasedName,
        true,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _lastErrorMeta = const i0.VerificationMeta(
    'lastError',
  );
  @override
  late final i0.GeneratedColumn<String> lastError = i0.GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _conflictDetailsMeta =
      const i0.VerificationMeta('conflictDetails');
  @override
  late final i0.GeneratedColumn<String> conflictDetails =
      i0.GeneratedColumn<String>(
        'conflict_details',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<i0.GeneratedColumn> get $columns => [
    id,
    actionId,
    patientId,
    actionType,
    payloadJson,
    timestamp,
    status,
    retryCount,
    nextRetryAt,
    lastError,
    conflictDetails,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_actions';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.SyncAction> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('action_id')) {
      context.handle(
        _actionIdMeta,
        actionId.isAcceptableOrUnknown(data['action_id']!, _actionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_actionIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('conflict_details')) {
      context.handle(
        _conflictDetailsMeta,
        conflictDetails.isAcceptableOrUnknown(
          data['conflict_details']!,
          _conflictDetailsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.SyncAction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.SyncAction(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      actionId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}action_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      actionType: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}action_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      status: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      nextRetryAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      conflictDetails: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}conflict_details'],
      ),
    );
  }

  @override
  $SyncActionsTable createAlias(String alias) {
    return $SyncActionsTable(attachedDatabase, alias);
  }
}

class SyncAction extends i0.DataClass implements i0.Insertable<i1.SyncAction> {
  final int id;

  /// Unique identifier for this action (timestamp-based).
  final String actionId;

  /// Which patient this action affects.
  final String patientId;

  /// Action type: REGISTER_PATIENT, UPDATE_HOUSING, ADD_FAMILY_MEMBER, etc.
  final String actionType;

  /// Serialized JSON payload for the mutation.
  final String payloadJson;

  /// When the action was enqueued (UTC).
  final DateTime timestamp;

  /// Current status: PENDING, IN_PROGRESS, FAILED, CONFLICT.
  final String status;

  /// Number of retry attempts so far.
  final int retryCount;

  /// When the next retry should happen (exponential backoff).
  final DateTime? nextRetryAt;

  /// Error message from the last failed attempt.
  final String? lastError;

  /// Details from a 409 version conflict.
  final String? conflictDetails;
  const SyncAction({
    required this.id,
    required this.actionId,
    required this.patientId,
    required this.actionType,
    required this.payloadJson,
    required this.timestamp,
    required this.status,
    required this.retryCount,
    this.nextRetryAt,
    this.lastError,
    this.conflictDetails,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['action_id'] = i0.Variable<String>(actionId);
    map['patient_id'] = i0.Variable<String>(patientId);
    map['action_type'] = i0.Variable<String>(actionType);
    map['payload_json'] = i0.Variable<String>(payloadJson);
    map['timestamp'] = i0.Variable<DateTime>(timestamp);
    map['status'] = i0.Variable<String>(status);
    map['retry_count'] = i0.Variable<int>(retryCount);
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = i0.Variable<DateTime>(nextRetryAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = i0.Variable<String>(lastError);
    }
    if (!nullToAbsent || conflictDetails != null) {
      map['conflict_details'] = i0.Variable<String>(conflictDetails);
    }
    return map;
  }

  i1.SyncActionsCompanion toCompanion(bool nullToAbsent) {
    return i1.SyncActionsCompanion(
      id: i0.Value(id),
      actionId: i0.Value(actionId),
      patientId: i0.Value(patientId),
      actionType: i0.Value(actionType),
      payloadJson: i0.Value(payloadJson),
      timestamp: i0.Value(timestamp),
      status: i0.Value(status),
      retryCount: i0.Value(retryCount),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(nextRetryAt),
      lastError: lastError == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(lastError),
      conflictDetails: conflictDetails == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(conflictDetails),
    );
  }

  factory SyncAction.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return SyncAction(
      id: serializer.fromJson<int>(json['id']),
      actionId: serializer.fromJson<String>(json['actionId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      actionType: serializer.fromJson<String>(json['actionType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      conflictDetails: serializer.fromJson<String?>(json['conflictDetails']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'actionId': serializer.toJson<String>(actionId),
      'patientId': serializer.toJson<String>(patientId),
      'actionType': serializer.toJson<String>(actionType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'lastError': serializer.toJson<String?>(lastError),
      'conflictDetails': serializer.toJson<String?>(conflictDetails),
    };
  }

  i1.SyncAction copyWith({
    int? id,
    String? actionId,
    String? patientId,
    String? actionType,
    String? payloadJson,
    DateTime? timestamp,
    String? status,
    int? retryCount,
    i0.Value<DateTime?> nextRetryAt = const i0.Value.absent(),
    i0.Value<String?> lastError = const i0.Value.absent(),
    i0.Value<String?> conflictDetails = const i0.Value.absent(),
  }) => i1.SyncAction(
    id: id ?? this.id,
    actionId: actionId ?? this.actionId,
    patientId: patientId ?? this.patientId,
    actionType: actionType ?? this.actionType,
    payloadJson: payloadJson ?? this.payloadJson,
    timestamp: timestamp ?? this.timestamp,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    conflictDetails: conflictDetails.present
        ? conflictDetails.value
        : this.conflictDetails,
  );
  SyncAction copyWithCompanion(i1.SyncActionsCompanion data) {
    return SyncAction(
      id: data.id.present ? data.id.value : this.id,
      actionId: data.actionId.present ? data.actionId.value : this.actionId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      conflictDetails: data.conflictDetails.present
          ? data.conflictDetails.value
          : this.conflictDetails,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncAction(')
          ..write('id: $id, ')
          ..write('actionId: $actionId, ')
          ..write('patientId: $patientId, ')
          ..write('actionType: $actionType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('timestamp: $timestamp, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('conflictDetails: $conflictDetails')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    actionId,
    patientId,
    actionType,
    payloadJson,
    timestamp,
    status,
    retryCount,
    nextRetryAt,
    lastError,
    conflictDetails,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.SyncAction &&
          other.id == this.id &&
          other.actionId == this.actionId &&
          other.patientId == this.patientId &&
          other.actionType == this.actionType &&
          other.payloadJson == this.payloadJson &&
          other.timestamp == this.timestamp &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.nextRetryAt == this.nextRetryAt &&
          other.lastError == this.lastError &&
          other.conflictDetails == this.conflictDetails);
}

class SyncActionsCompanion extends i0.UpdateCompanion<i1.SyncAction> {
  final i0.Value<int> id;
  final i0.Value<String> actionId;
  final i0.Value<String> patientId;
  final i0.Value<String> actionType;
  final i0.Value<String> payloadJson;
  final i0.Value<DateTime> timestamp;
  final i0.Value<String> status;
  final i0.Value<int> retryCount;
  final i0.Value<DateTime?> nextRetryAt;
  final i0.Value<String?> lastError;
  final i0.Value<String?> conflictDetails;
  const SyncActionsCompanion({
    this.id = const i0.Value.absent(),
    this.actionId = const i0.Value.absent(),
    this.patientId = const i0.Value.absent(),
    this.actionType = const i0.Value.absent(),
    this.payloadJson = const i0.Value.absent(),
    this.timestamp = const i0.Value.absent(),
    this.status = const i0.Value.absent(),
    this.retryCount = const i0.Value.absent(),
    this.nextRetryAt = const i0.Value.absent(),
    this.lastError = const i0.Value.absent(),
    this.conflictDetails = const i0.Value.absent(),
  });
  SyncActionsCompanion.insert({
    this.id = const i0.Value.absent(),
    required String actionId,
    required String patientId,
    required String actionType,
    required String payloadJson,
    required DateTime timestamp,
    this.status = const i0.Value.absent(),
    this.retryCount = const i0.Value.absent(),
    this.nextRetryAt = const i0.Value.absent(),
    this.lastError = const i0.Value.absent(),
    this.conflictDetails = const i0.Value.absent(),
  }) : actionId = i0.Value(actionId),
       patientId = i0.Value(patientId),
       actionType = i0.Value(actionType),
       payloadJson = i0.Value(payloadJson),
       timestamp = i0.Value(timestamp);
  static i0.Insertable<i1.SyncAction> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? actionId,
    i0.Expression<String>? patientId,
    i0.Expression<String>? actionType,
    i0.Expression<String>? payloadJson,
    i0.Expression<DateTime>? timestamp,
    i0.Expression<String>? status,
    i0.Expression<int>? retryCount,
    i0.Expression<DateTime>? nextRetryAt,
    i0.Expression<String>? lastError,
    i0.Expression<String>? conflictDetails,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (actionId != null) 'action_id': actionId,
      if (patientId != null) 'patient_id': patientId,
      if (actionType != null) 'action_type': actionType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (timestamp != null) 'timestamp': timestamp,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (lastError != null) 'last_error': lastError,
      if (conflictDetails != null) 'conflict_details': conflictDetails,
    });
  }

  i1.SyncActionsCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<String>? actionId,
    i0.Value<String>? patientId,
    i0.Value<String>? actionType,
    i0.Value<String>? payloadJson,
    i0.Value<DateTime>? timestamp,
    i0.Value<String>? status,
    i0.Value<int>? retryCount,
    i0.Value<DateTime?>? nextRetryAt,
    i0.Value<String?>? lastError,
    i0.Value<String?>? conflictDetails,
  }) {
    return i1.SyncActionsCompanion(
      id: id ?? this.id,
      actionId: actionId ?? this.actionId,
      patientId: patientId ?? this.patientId,
      actionType: actionType ?? this.actionType,
      payloadJson: payloadJson ?? this.payloadJson,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastError: lastError ?? this.lastError,
      conflictDetails: conflictDetails ?? this.conflictDetails,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (actionId.present) {
      map['action_id'] = i0.Variable<String>(actionId.value);
    }
    if (patientId.present) {
      map['patient_id'] = i0.Variable<String>(patientId.value);
    }
    if (actionType.present) {
      map['action_type'] = i0.Variable<String>(actionType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = i0.Variable<String>(payloadJson.value);
    }
    if (timestamp.present) {
      map['timestamp'] = i0.Variable<DateTime>(timestamp.value);
    }
    if (status.present) {
      map['status'] = i0.Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = i0.Variable<int>(retryCount.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = i0.Variable<DateTime>(nextRetryAt.value);
    }
    if (lastError.present) {
      map['last_error'] = i0.Variable<String>(lastError.value);
    }
    if (conflictDetails.present) {
      map['conflict_details'] = i0.Variable<String>(conflictDetails.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncActionsCompanion(')
          ..write('id: $id, ')
          ..write('actionId: $actionId, ')
          ..write('patientId: $patientId, ')
          ..write('actionType: $actionType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('timestamp: $timestamp, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('conflictDetails: $conflictDetails')
          ..write(')'))
        .toString();
  }
}
