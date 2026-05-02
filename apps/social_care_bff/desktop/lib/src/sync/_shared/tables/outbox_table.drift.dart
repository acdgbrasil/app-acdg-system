// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:social_care_desktop/src/sync/_shared/tables/outbox_table.drift.dart'
    as i1;
import 'package:social_care_desktop/src/sync/_shared/tables/outbox_table.dart'
    as i2;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i3;

typedef $$OutboxTableCreateCompanionBuilder =
    i1.OutboxCompanion Function({
      required String id,
      required String aggregateType,
      required String aggregateId,
      required String mutationType,
      required String payload,
      required int expectedVersion,
      required DateTime createdAt,
      i0.Value<int> attemptCount,
      i0.Value<DateTime?> lastAttemptAt,
      i0.Value<String?> lastError,
      required String status,
      i0.Value<int> rowid,
    });
typedef $$OutboxTableUpdateCompanionBuilder =
    i1.OutboxCompanion Function({
      i0.Value<String> id,
      i0.Value<String> aggregateType,
      i0.Value<String> aggregateId,
      i0.Value<String> mutationType,
      i0.Value<String> payload,
      i0.Value<int> expectedVersion,
      i0.Value<DateTime> createdAt,
      i0.Value<int> attemptCount,
      i0.Value<DateTime?> lastAttemptAt,
      i0.Value<String?> lastError,
      i0.Value<String> status,
      i0.Value<int> rowid,
    });

class $$OutboxTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$OutboxTable> {
  $$OutboxTableFilterComposer({
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

  i0.ColumnFilters<String> get aggregateType => $composableBuilder(
    column: $table.aggregateType,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get aggregateId => $composableBuilder(
    column: $table.aggregateId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get mutationType => $composableBuilder(
    column: $table.mutationType,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get expectedVersion => $composableBuilder(
    column: $table.expectedVersion,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$OutboxTable> {
  $$OutboxTableOrderingComposer({
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

  i0.ColumnOrderings<String> get aggregateType => $composableBuilder(
    column: $table.aggregateType,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get aggregateId => $composableBuilder(
    column: $table.aggregateId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get mutationType => $composableBuilder(
    column: $table.mutationType,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get expectedVersion => $composableBuilder(
    column: $table.expectedVersion,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get aggregateType => $composableBuilder(
    column: $table.aggregateType,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get aggregateId => $composableBuilder(
    column: $table.aggregateId,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get mutationType => $composableBuilder(
    column: $table.mutationType,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  i0.GeneratedColumn<int> get expectedVersion => $composableBuilder(
    column: $table.expectedVersion,
    builder: (column) => column,
  );

  i0.GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  i0.GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  i0.GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  i0.GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$OutboxTable,
          i1.OutboxData,
          i1.$$OutboxTableFilterComposer,
          i1.$$OutboxTableOrderingComposer,
          i1.$$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (
            i1.OutboxData,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$OutboxTable,
              i1.OutboxData
            >,
          ),
          i1.OutboxData,
          i0.PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(i0.GeneratedDatabase db, i1.$OutboxTable table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> aggregateType = const i0.Value.absent(),
                i0.Value<String> aggregateId = const i0.Value.absent(),
                i0.Value<String> mutationType = const i0.Value.absent(),
                i0.Value<String> payload = const i0.Value.absent(),
                i0.Value<int> expectedVersion = const i0.Value.absent(),
                i0.Value<DateTime> createdAt = const i0.Value.absent(),
                i0.Value<int> attemptCount = const i0.Value.absent(),
                i0.Value<DateTime?> lastAttemptAt = const i0.Value.absent(),
                i0.Value<String?> lastError = const i0.Value.absent(),
                i0.Value<String> status = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.OutboxCompanion(
                id: id,
                aggregateType: aggregateType,
                aggregateId: aggregateId,
                mutationType: mutationType,
                payload: payload,
                expectedVersion: expectedVersion,
                createdAt: createdAt,
                attemptCount: attemptCount,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String aggregateType,
                required String aggregateId,
                required String mutationType,
                required String payload,
                required int expectedVersion,
                required DateTime createdAt,
                i0.Value<int> attemptCount = const i0.Value.absent(),
                i0.Value<DateTime?> lastAttemptAt = const i0.Value.absent(),
                i0.Value<String?> lastError = const i0.Value.absent(),
                required String status,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.OutboxCompanion.insert(
                id: id,
                aggregateType: aggregateType,
                aggregateId: aggregateId,
                mutationType: mutationType,
                payload: payload,
                expectedVersion: expectedVersion,
                createdAt: createdAt,
                attemptCount: attemptCount,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$OutboxTable,
      i1.OutboxData,
      i1.$$OutboxTableFilterComposer,
      i1.$$OutboxTableOrderingComposer,
      i1.$$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (
        i1.OutboxData,
        i0.BaseReferences<i0.GeneratedDatabase, i1.$OutboxTable, i1.OutboxData>,
      ),
      i1.OutboxData,
      i0.PrefetchHooks Function()
    >;
i0.Index get outboxStatusCreatedIdx => i0.Index(
  'outbox_status_created_idx',
  'CREATE INDEX outbox_status_created_idx ON outbox (status, created_at)',
);

class $OutboxTable extends i2.Outbox
    with i0.TableInfo<$OutboxTable, i1.OutboxData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<String> id = i0.GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _aggregateTypeMeta =
      const i0.VerificationMeta('aggregateType');
  @override
  late final i0.GeneratedColumn<String> aggregateType =
      i0.GeneratedColumn<String>(
        'aggregate_type',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _aggregateIdMeta = const i0.VerificationMeta(
    'aggregateId',
  );
  @override
  late final i0.GeneratedColumn<String> aggregateId =
      i0.GeneratedColumn<String>(
        'aggregate_id',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _mutationTypeMeta =
      const i0.VerificationMeta('mutationType');
  @override
  late final i0.GeneratedColumn<String> mutationType =
      i0.GeneratedColumn<String>(
        'mutation_type',
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
  static const i0.VerificationMeta _expectedVersionMeta =
      const i0.VerificationMeta('expectedVersion');
  @override
  late final i0.GeneratedColumn<int> expectedVersion = i0.GeneratedColumn<int>(
    'expected_version',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _createdAtMeta = const i0.VerificationMeta(
    'createdAt',
  );
  @override
  late final i0.GeneratedColumn<DateTime> createdAt =
      i0.GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _attemptCountMeta =
      const i0.VerificationMeta('attemptCount');
  @override
  late final i0.GeneratedColumn<int> attemptCount = i0.GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const i3.Constant(0),
  );
  static const i0.VerificationMeta _lastAttemptAtMeta =
      const i0.VerificationMeta('lastAttemptAt');
  @override
  late final i0.GeneratedColumn<DateTime> lastAttemptAt =
      i0.GeneratedColumn<DateTime>(
        'last_attempt_at',
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
  @override
  List<i0.GeneratedColumn> get $columns => [
    id,
    aggregateType,
    aggregateId,
    mutationType,
    payload,
    expectedVersion,
    createdAt,
    attemptCount,
    lastAttemptAt,
    lastError,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.OutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('aggregate_type')) {
      context.handle(
        _aggregateTypeMeta,
        aggregateType.isAcceptableOrUnknown(
          data['aggregate_type']!,
          _aggregateTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aggregateTypeMeta);
    }
    if (data.containsKey('aggregate_id')) {
      context.handle(
        _aggregateIdMeta,
        aggregateId.isAcceptableOrUnknown(
          data['aggregate_id']!,
          _aggregateIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aggregateIdMeta);
    }
    if (data.containsKey('mutation_type')) {
      context.handle(
        _mutationTypeMeta,
        mutationType.isAcceptableOrUnknown(
          data['mutation_type']!,
          _mutationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mutationTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('expected_version')) {
      context.handle(
        _expectedVersionMeta,
        expectedVersion.isAcceptableOrUnknown(
          data['expected_version']!,
          _expectedVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expectedVersionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
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
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.OutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.OutboxData(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      aggregateType: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}aggregate_type'],
      )!,
      aggregateId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}aggregate_id'],
      )!,
      mutationType: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}mutation_type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      expectedVersion: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}expected_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      status: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxData extends i0.DataClass implements i0.Insertable<i1.OutboxData> {
  /// UUID v4. Idempotency key — re-enqueueing the same mutation is a
  /// no-op (the drain has already processed it or is about to).
  final String id;

  /// Aggregate root the mutation targets — `'patient'`, `'appointment'`,
  /// `'referral'`, `'violation_report'`, `'lookup_item'`,
  /// `'lookup_request'`. Used for invalidation hints; not for routing
  /// (routing is by [mutationType]).
  final String aggregateType;

  /// Identity of the entity being mutated (UUID for patient/appointment/
  /// referral/violation_report/lookup_request; table name for
  /// lookup_item creates).
  final String aggregateId;

  /// Discriminator for the mutation kind — one of the 27 values listed
  /// in STATE.md. Drives the dispatch table in `SyncEngine` and the
  /// `SyncMutation.fromOutboxEntry` switch.
  final String mutationType;

  /// Serialized request body (`request.toJson()`) as JSON text. Body-less
  /// mutations (admit/approve/reject) store `'{}'`.
  final String payload;

  /// Optimistic-locking version expected at the backend. Forward-compat
  /// (D1 (a)): written today, ignored by Vapor today, used when
  /// concurrency control lands. Never decremented.
  final int expectedVersion;

  /// Wall-clock at enqueue. FIFO ordering of the drain depends on this
  /// being monotonic per producer; concurrent producers are tie-broken
  /// by SQL row order (acceptable — A18b serializes writes per
  /// aggregate).
  final DateTime createdAt;

  /// Number of attempts that have failed (retriable) so far. Read by
  /// `RetryPolicy.shouldRetry` to decide pending vs. failed_dead.
  final int attemptCount;

  /// Wall-clock of the most recent attempt (success or failure). Null
  /// before the first dispatch.
  final DateTime? lastAttemptAt;

  /// Human-readable error string from the most recent failure. Cleared
  /// implicitly when the row resets to pending.
  final String? lastError;

  /// Lifecycle state. Lowercase snake_case; see `OutboxStatus` for the
  /// canonical enum. `pending` | `in_flight` | `failed_retriable` |
  /// `failed_dead` | `completed`.
  final String status;
  const OutboxData({
    required this.id,
    required this.aggregateType,
    required this.aggregateId,
    required this.mutationType,
    required this.payload,
    required this.expectedVersion,
    required this.createdAt,
    required this.attemptCount,
    this.lastAttemptAt,
    this.lastError,
    required this.status,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<String>(id);
    map['aggregate_type'] = i0.Variable<String>(aggregateType);
    map['aggregate_id'] = i0.Variable<String>(aggregateId);
    map['mutation_type'] = i0.Variable<String>(mutationType);
    map['payload'] = i0.Variable<String>(payload);
    map['expected_version'] = i0.Variable<int>(expectedVersion);
    map['created_at'] = i0.Variable<DateTime>(createdAt);
    map['attempt_count'] = i0.Variable<int>(attemptCount);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = i0.Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = i0.Variable<String>(lastError);
    }
    map['status'] = i0.Variable<String>(status);
    return map;
  }

  i1.OutboxCompanion toCompanion(bool nullToAbsent) {
    return i1.OutboxCompanion(
      id: i0.Value(id),
      aggregateType: i0.Value(aggregateType),
      aggregateId: i0.Value(aggregateId),
      mutationType: i0.Value(mutationType),
      payload: i0.Value(payload),
      expectedVersion: i0.Value(expectedVersion),
      createdAt: i0.Value(createdAt),
      attemptCount: i0.Value(attemptCount),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(lastAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(lastError),
      status: i0.Value(status),
    );
  }

  factory OutboxData.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return OutboxData(
      id: serializer.fromJson<String>(json['id']),
      aggregateType: serializer.fromJson<String>(json['aggregateType']),
      aggregateId: serializer.fromJson<String>(json['aggregateId']),
      mutationType: serializer.fromJson<String>(json['mutationType']),
      payload: serializer.fromJson<String>(json['payload']),
      expectedVersion: serializer.fromJson<int>(json['expectedVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'aggregateType': serializer.toJson<String>(aggregateType),
      'aggregateId': serializer.toJson<String>(aggregateId),
      'mutationType': serializer.toJson<String>(mutationType),
      'payload': serializer.toJson<String>(payload),
      'expectedVersion': serializer.toJson<int>(expectedVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'status': serializer.toJson<String>(status),
    };
  }

  i1.OutboxData copyWith({
    String? id,
    String? aggregateType,
    String? aggregateId,
    String? mutationType,
    String? payload,
    int? expectedVersion,
    DateTime? createdAt,
    int? attemptCount,
    i0.Value<DateTime?> lastAttemptAt = const i0.Value.absent(),
    i0.Value<String?> lastError = const i0.Value.absent(),
    String? status,
  }) => i1.OutboxData(
    id: id ?? this.id,
    aggregateType: aggregateType ?? this.aggregateType,
    aggregateId: aggregateId ?? this.aggregateId,
    mutationType: mutationType ?? this.mutationType,
    payload: payload ?? this.payload,
    expectedVersion: expectedVersion ?? this.expectedVersion,
    createdAt: createdAt ?? this.createdAt,
    attemptCount: attemptCount ?? this.attemptCount,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    status: status ?? this.status,
  );
  OutboxData copyWithCompanion(i1.OutboxCompanion data) {
    return OutboxData(
      id: data.id.present ? data.id.value : this.id,
      aggregateType: data.aggregateType.present
          ? data.aggregateType.value
          : this.aggregateType,
      aggregateId: data.aggregateId.present
          ? data.aggregateId.value
          : this.aggregateId,
      mutationType: data.mutationType.present
          ? data.mutationType.value
          : this.mutationType,
      payload: data.payload.present ? data.payload.value : this.payload,
      expectedVersion: data.expectedVersion.present
          ? data.expectedVersion.value
          : this.expectedVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxData(')
          ..write('id: $id, ')
          ..write('aggregateType: $aggregateType, ')
          ..write('aggregateId: $aggregateId, ')
          ..write('mutationType: $mutationType, ')
          ..write('payload: $payload, ')
          ..write('expectedVersion: $expectedVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    aggregateType,
    aggregateId,
    mutationType,
    payload,
    expectedVersion,
    createdAt,
    attemptCount,
    lastAttemptAt,
    lastError,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.OutboxData &&
          other.id == this.id &&
          other.aggregateType == this.aggregateType &&
          other.aggregateId == this.aggregateId &&
          other.mutationType == this.mutationType &&
          other.payload == this.payload &&
          other.expectedVersion == this.expectedVersion &&
          other.createdAt == this.createdAt &&
          other.attemptCount == this.attemptCount &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastError == this.lastError &&
          other.status == this.status);
}

class OutboxCompanion extends i0.UpdateCompanion<i1.OutboxData> {
  final i0.Value<String> id;
  final i0.Value<String> aggregateType;
  final i0.Value<String> aggregateId;
  final i0.Value<String> mutationType;
  final i0.Value<String> payload;
  final i0.Value<int> expectedVersion;
  final i0.Value<DateTime> createdAt;
  final i0.Value<int> attemptCount;
  final i0.Value<DateTime?> lastAttemptAt;
  final i0.Value<String?> lastError;
  final i0.Value<String> status;
  final i0.Value<int> rowid;
  const OutboxCompanion({
    this.id = const i0.Value.absent(),
    this.aggregateType = const i0.Value.absent(),
    this.aggregateId = const i0.Value.absent(),
    this.mutationType = const i0.Value.absent(),
    this.payload = const i0.Value.absent(),
    this.expectedVersion = const i0.Value.absent(),
    this.createdAt = const i0.Value.absent(),
    this.attemptCount = const i0.Value.absent(),
    this.lastAttemptAt = const i0.Value.absent(),
    this.lastError = const i0.Value.absent(),
    this.status = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  OutboxCompanion.insert({
    required String id,
    required String aggregateType,
    required String aggregateId,
    required String mutationType,
    required String payload,
    required int expectedVersion,
    required DateTime createdAt,
    this.attemptCount = const i0.Value.absent(),
    this.lastAttemptAt = const i0.Value.absent(),
    this.lastError = const i0.Value.absent(),
    required String status,
    this.rowid = const i0.Value.absent(),
  }) : id = i0.Value(id),
       aggregateType = i0.Value(aggregateType),
       aggregateId = i0.Value(aggregateId),
       mutationType = i0.Value(mutationType),
       payload = i0.Value(payload),
       expectedVersion = i0.Value(expectedVersion),
       createdAt = i0.Value(createdAt),
       status = i0.Value(status);
  static i0.Insertable<i1.OutboxData> custom({
    i0.Expression<String>? id,
    i0.Expression<String>? aggregateType,
    i0.Expression<String>? aggregateId,
    i0.Expression<String>? mutationType,
    i0.Expression<String>? payload,
    i0.Expression<int>? expectedVersion,
    i0.Expression<DateTime>? createdAt,
    i0.Expression<int>? attemptCount,
    i0.Expression<DateTime>? lastAttemptAt,
    i0.Expression<String>? lastError,
    i0.Expression<String>? status,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (aggregateType != null) 'aggregate_type': aggregateType,
      if (aggregateId != null) 'aggregate_id': aggregateId,
      if (mutationType != null) 'mutation_type': mutationType,
      if (payload != null) 'payload': payload,
      if (expectedVersion != null) 'expected_version': expectedVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.OutboxCompanion copyWith({
    i0.Value<String>? id,
    i0.Value<String>? aggregateType,
    i0.Value<String>? aggregateId,
    i0.Value<String>? mutationType,
    i0.Value<String>? payload,
    i0.Value<int>? expectedVersion,
    i0.Value<DateTime>? createdAt,
    i0.Value<int>? attemptCount,
    i0.Value<DateTime?>? lastAttemptAt,
    i0.Value<String?>? lastError,
    i0.Value<String>? status,
    i0.Value<int>? rowid,
  }) {
    return i1.OutboxCompanion(
      id: id ?? this.id,
      aggregateType: aggregateType ?? this.aggregateType,
      aggregateId: aggregateId ?? this.aggregateId,
      mutationType: mutationType ?? this.mutationType,
      payload: payload ?? this.payload,
      expectedVersion: expectedVersion ?? this.expectedVersion,
      createdAt: createdAt ?? this.createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: lastError ?? this.lastError,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<String>(id.value);
    }
    if (aggregateType.present) {
      map['aggregate_type'] = i0.Variable<String>(aggregateType.value);
    }
    if (aggregateId.present) {
      map['aggregate_id'] = i0.Variable<String>(aggregateId.value);
    }
    if (mutationType.present) {
      map['mutation_type'] = i0.Variable<String>(mutationType.value);
    }
    if (payload.present) {
      map['payload'] = i0.Variable<String>(payload.value);
    }
    if (expectedVersion.present) {
      map['expected_version'] = i0.Variable<int>(expectedVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = i0.Variable<DateTime>(createdAt.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = i0.Variable<int>(attemptCount.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = i0.Variable<DateTime>(lastAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = i0.Variable<String>(lastError.value);
    }
    if (status.present) {
      map['status'] = i0.Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('id: $id, ')
          ..write('aggregateType: $aggregateType, ')
          ..write('aggregateId: $aggregateId, ')
          ..write('mutationType: $mutationType, ')
          ..write('payload: $payload, ')
          ..write('expectedVersion: $expectedVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}
