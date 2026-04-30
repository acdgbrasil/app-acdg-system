import 'package:dio/dio.dart';
import 'package:shared/shared.dart';

/// Sealed decision returned by [ConflictResolver.decide]. The engine
/// translates each variant to a state transition on the Outbox row.
sealed class SyncDecision {
  const SyncDecision();
}

/// Drain succeeded after re-checking — the row is already up-to-date.
/// Currently unused on the failure path; reserved for future success-
/// classification scenarios (e.g. server returns "already applied").
final class CompletedDecision extends SyncDecision {
  const CompletedDecision();
}

/// Transient failure — re-queue with backoff. Carries a human-readable
/// reason for the `lastError` column.
final class RetriableDecision extends SyncDecision {
  const RetriableDecision(this.reason);
  final String reason;
}

/// Terminal failure — manual reconciliation (D2 (B)). Surfaces in the
/// UI for the user to resolve.
final class DeadDecision extends SyncDecision {
  const DeadDecision(this.reason);
  final String reason;
}

/// Maps an arbitrary error returned by a sub-contract call onto a
/// [SyncDecision].
///
/// Mapping rules (see STATE.md):
///  - 409 BackendError                → DeadDecision (manual reconcile)
///  - 5xx BackendError                → RetriableDecision (server fault)
///  - 4xx BackendError (other than 409) → DeadDecision (caller error)
///  - DioException                    → RetriableDecision (network)
///  - anything else                   → RetriableDecision (conservative)
class ConflictResolver {
  const ConflictResolver();

  SyncDecision decide(Object error) {
    if (error is BackendErrorResponse) {
      final http = error.error.http;
      if (http != null) {
        if (http == 409) {
          return DeadDecision(
            'OPTIMISTIC_LOCK_CONFLICT: ${error.error.message}',
          );
        }
        if (http >= 500) {
          return RetriableDecision(
            'Server error $http: ${error.error.message}',
          );
        }
        if (http >= 400) {
          return DeadDecision('Client error $http: ${error.error.message}');
        }
      }
      // Backend error without an http code — conservative retry.
      return RetriableDecision('Backend error: ${error.error.message}');
    }
    if (error is DioException) {
      return RetriableDecision('Network: ${error.message ?? error.type.name}');
    }
    return RetriableDecision('Unknown error: $error');
  }
}
