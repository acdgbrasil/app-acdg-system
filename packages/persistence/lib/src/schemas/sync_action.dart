import 'package:isar/isar.dart';

part 'sync_action.g.dart';

@collection
class SyncAction {
  Id id = Isar.autoIncrement;

  @Index()
  late String actionId; // UUID

  @Index()
  late String patientId;

  late String actionType; // e.g., 'REGISTER_PATIENT', 'UPDATE_HOUSING'

  late String payloadJson; // Serialized JSON request

  @Index()
  late DateTime timestamp;

  @Index()
  late String status; // 'PENDING', 'IN_PROGRESS', 'FAILED', 'CONFLICT'

  int retryCount = 0;

  DateTime? nextRetryAt;

  String? lastError;

  String? conflictDetails;
}
