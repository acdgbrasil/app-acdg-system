import 'package:core_contracts/core_contracts.dart';

import '../dto/requests/governance/create_lookup_item_request.dart';
import '../dto/requests/governance/create_lookup_request_request.dart';
import '../dto/requests/governance/toggle_lookup_item_request.dart';
import '../dto/requests/governance/update_lookup_item_request.dart';
import '../dto/responses/governance/lookup_item_response.dart';
import '../dto/responses/governance/lookup_request_response.dart';
import '../dto/responses/governance/lookups_batch_response.dart';
import '../dto/shared/standard_response.dart';

/// Lookup contract — domain tables (`dominio_*`) and governance requests.
///
/// Covers two related capabilities:
/// - **Reading** lookup tables (single or batch) consumed by form dropdowns.
/// - **Governance**: admin creates/updates/toggles items, and end-users
///   submit governance requests to propose new items for review.
abstract interface class LookupContract {
  // ── Item queries ──────────────────────────────────────────────────────

  /// Fetches a single lookup table by name (e.g. `dominio_parentesco`).
  Future<Result<StandardResponse<List<LookupItemResponse>>>> getLookupTable(
    String tableName,
  );

  /// Fetches multiple lookup tables in a single call.
  ///
  /// Contract A composite endpoint that replaces N client-side calls
  /// (was `Future.wait([...])` in `PatientRegistrationViewModel`).
  Future<Result<StandardResponse<LookupsBatchResponse>>> getLookupsBatch(
    List<String> tables,
  );

  // ── Item admin ────────────────────────────────────────────────────────

  /// Creates a new lookup item in [tableName]. Admin-only.
  Future<Result<StandardIdResponse>> createLookupItem(
    String tableName,
    CreateLookupItemRequest request,
  );

  /// Updates an existing lookup item (partial). Admin-only.
  Future<Result<StandardResponse<void>>> updateLookupItem(
    String tableName,
    String itemId,
    UpdateLookupItemRequest request,
  );

  /// Toggles active/inactive state of a lookup item. Admin-only.
  Future<Result<StandardResponse<void>>> toggleLookupItem(
    String tableName,
    String itemId,
    ToggleLookupItemRequest request,
  );

  // ── Governance requests ───────────────────────────────────────────────

  /// Lists all pending/approved/rejected lookup governance requests.
  Future<Result<StandardResponse<List<LookupRequestResponse>>>>
  getLookupRequests();

  /// Creates a new governance request (proposed new lookup item).
  Future<Result<StandardIdResponse>> createLookupRequest(
    CreateLookupRequestRequest request,
  );

  /// Approves a pending governance request. Admin-only.
  Future<Result<StandardResponse<void>>> approveLookupRequest(String requestId);

  /// Rejects a pending governance request. Admin-only.
  Future<Result<StandardResponse<void>>> rejectLookupRequest(String requestId);
}
