/// Bundles the single Audit use case (A18b-v2):
///   * `FetchAuditTrailUseCase` — read, `auditCache` + `auditRemote`
///                                + clock + staleAfter (Pattern 1)
///
/// Yes — a builder for one use case. The point isn't economy, it's
/// **uniformity**: when a `RecordAuditEventUseCase` lands later (D03/D6),
/// `social_care_desktop.dart` doesn't change — only [AuditUseCases] does.
library;

import 'package:shared/shared.dart';

import '../../../cache/contracts/audit_cache.dart';
import '../../../use_cases/_shared/clock.dart';
import '../../../use_cases/audit/fetch_audit_trail_use_case.dart';

/// Data class grouping the 1 Audit use case.
class AuditUseCases {
  AuditUseCases({required this.fetchAuditTrail});

  final FetchAuditTrailUseCase fetchAuditTrail;

  /// Constructs the Audit use case(s) from shared dependencies.
  static AuditUseCases build({
    required AuditCache auditCache,
    required AuditContract remote,
    required Clock clock,
    required Duration staleAfter,
  }) {
    return AuditUseCases(
      fetchAuditTrail: FetchAuditTrailUseCase(
        cache: auditCache,
        remote: remote,
        clock: clock,
        staleAfter: staleAfter,
      ),
    );
  }
}
