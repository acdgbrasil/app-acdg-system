/// Bundles the 10 Lookup use cases (A18b-v2) — a mix of reads
/// (cache + remote + staleAfter) and writes (cache + outbox + engine):
///   Reads (4):
///     * `GetLookupTableUseCase`, `GetLookupsBatchUseCase`,
///       `ListLookupRequestsUseCase`, `FindLookupRequestByIdUseCase`
///   Writes (6):
///     * `CreateLookupItemUseCase`, `UpdateLookupItemUseCase`,
///       `ToggleLookupItemUseCase`, `CreateLookupRequestUseCase`,
///       `ApproveLookupRequestUseCase`, `RejectLookupRequestUseCase`
library;

import 'package:shared/shared.dart';

import '../../../cache/contracts/lookup_cache.dart';
import '../../../sync/engine/sync_engine.dart';
import '../../../sync/outbox/outbox_repository.dart';
import '../../../use_cases/_shared/clock.dart';
import '../../../use_cases/lookup/approve_lookup_request_use_case.dart';
import '../../../use_cases/lookup/create_lookup_item_use_case.dart';
import '../../../use_cases/lookup/create_lookup_request_use_case.dart';
import '../../../use_cases/lookup/find_lookup_request_by_id_use_case.dart';
import '../../../use_cases/lookup/get_lookup_table_use_case.dart';
import '../../../use_cases/lookup/get_lookups_batch_use_case.dart';
import '../../../use_cases/lookup/list_lookup_requests_use_case.dart';
import '../../../use_cases/lookup/reject_lookup_request_use_case.dart';
import '../../../use_cases/lookup/toggle_lookup_item_use_case.dart';
import '../../../use_cases/lookup/update_lookup_item_use_case.dart';

/// Data class grouping the 10 Lookup use cases.
class LookupUseCases {
  LookupUseCases({
    required this.getLookupTable,
    required this.getLookupsBatch,
    required this.createLookupItem,
    required this.updateLookupItem,
    required this.toggleLookupItem,
    required this.createLookupRequest,
    required this.listLookupRequests,
    required this.findLookupRequestById,
    required this.approveLookupRequest,
    required this.rejectLookupRequest,
  });

  // ── Reads ───────────────────────────────────────────────────────────
  final GetLookupTableUseCase getLookupTable;
  final GetLookupsBatchUseCase getLookupsBatch;
  final ListLookupRequestsUseCase listLookupRequests;
  final FindLookupRequestByIdUseCase findLookupRequestById;

  // ── Writes ──────────────────────────────────────────────────────────
  final CreateLookupItemUseCase createLookupItem;
  final UpdateLookupItemUseCase updateLookupItem;
  final ToggleLookupItemUseCase toggleLookupItem;
  final CreateLookupRequestUseCase createLookupRequest;
  final ApproveLookupRequestUseCase approveLookupRequest;
  final RejectLookupRequestUseCase rejectLookupRequest;

  /// Constructs all 10 Lookup use cases from shared dependencies.
  static LookupUseCases build({
    required LookupCache lookupCache,
    required LookupContract remote,
    required OutboxRepository outbox,
    required SyncEngine engine,
    required Clock clock,
    required Duration staleAfter,
  }) {
    return LookupUseCases(
      // Reads
      getLookupTable: GetLookupTableUseCase(
        cache: lookupCache,
        remote: remote,
        clock: clock,
        staleAfter: staleAfter,
      ),
      getLookupsBatch: GetLookupsBatchUseCase(
        cache: lookupCache,
        remote: remote,
        clock: clock,
        staleAfter: staleAfter,
      ),
      listLookupRequests: ListLookupRequestsUseCase(
        cache: lookupCache,
        remote: remote,
        clock: clock,
        staleAfter: staleAfter,
      ),
      findLookupRequestById: FindLookupRequestByIdUseCase(
        cache: lookupCache,
        remote: remote,
        clock: clock,
        staleAfter: staleAfter,
      ),
      // Writes
      createLookupItem: CreateLookupItemUseCase(
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      updateLookupItem: UpdateLookupItemUseCase(
        cache: lookupCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      toggleLookupItem: ToggleLookupItemUseCase(
        cache: lookupCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      createLookupRequest: CreateLookupRequestUseCase(
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      approveLookupRequest: ApproveLookupRequestUseCase(
        cache: lookupCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
      rejectLookupRequest: RejectLookupRequestUseCase(
        cache: lookupCache,
        outbox: outbox,
        engine: engine,
        clock: clock,
      ),
    );
  }
}
