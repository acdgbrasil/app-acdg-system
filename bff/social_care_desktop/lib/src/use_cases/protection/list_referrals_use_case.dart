import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../cache/contracts/protection_cache.dart';
import '../_shared/clock.dart';

/// Pattern 1 — cache-only read.
///
/// `ProtectionContract` does not expose list endpoints (only mutating
/// endpoints + single-id reads), so we serve what the cache holds. On
/// miss we return `Success([])`.
class ListReferralsUseCase {
  ListReferralsUseCase({
    required ProtectionCache cache,
    required Clock clock,
    Duration staleAfter = const Duration(minutes: 5),
  }) : _cache = cache;

  final ProtectionCache _cache;

  Future<Result<List<ReferralResponse>>> call(String patientId) async {
    final cachedResult = await _cache.listReferrals(patientId);
    switch (cachedResult) {
      case Success(:final value):
        return Success<List<ReferralResponse>>(value);
      case Failure(:final error, :final stackTrace):
        return Failure<List<ReferralResponse>>(error, stackTrace: stackTrace);
    }
  }
}
