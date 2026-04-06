import 'package:shared/shared.dart';

/// Abstraction for local cache operations beyond [SocialCareContract].
///
/// Extends the standard contract with cache-specific methods required
/// by [OfflineFirstRepository] to manage sync state and local storage.
abstract class LocalCacheContract implements SocialCareContract {
  /// Whether the patient has pending actions in the sync queue.
  Future<bool> hasPendingActions(PatientId patientId);

  /// Updates the local cache with a remote patient snapshot.
  Future<void> updateCacheFromRemote(PatientRemote dto);

  /// Updates the local cache with patient overview summaries.
  Future<void> updateCacheFromSummaries(List<PatientOverview> summaries);

  /// Updates the local lookup table cache.
  Future<void> updateLookupCache(String tableName, List<LookupItem> items);
}
