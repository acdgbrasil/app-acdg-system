import 'package:drift/drift.dart';

/// Queue of pending synchronization actions.
///
/// Each row represents a mutation that happened locally
/// and needs to be replayed against the backend.
class SyncActions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Unique identifier for this action (timestamp-based).
  TextColumn get actionId => text()();

  /// Which patient this action affects.
  TextColumn get patientId => text()();

  /// Action type: REGISTER_PATIENT, UPDATE_HOUSING, ADD_FAMILY_MEMBER, etc.
  TextColumn get actionType => text()();

  /// Serialized JSON payload for the mutation.
  TextColumn get payloadJson => text()();

  /// When the action was enqueued (UTC).
  DateTimeColumn get timestamp => dateTime()();

  /// Current status: PENDING, IN_PROGRESS, FAILED, CONFLICT.
  TextColumn get status => text().withDefault(const Constant('PENDING'))();

  /// Number of retry attempts so far.
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// When the next retry should happen (exponential backoff).
  DateTimeColumn get nextRetryAt => dateTime().nullable()();

  /// Error message from the last failed attempt.
  TextColumn get lastError => text().nullable()();

  /// Details from a 409 version conflict.
  TextColumn get conflictDetails => text().nullable()();
}
