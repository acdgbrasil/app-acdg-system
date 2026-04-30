/// BFF implementation for Desktop (in-process).
///
/// A16-v2 (Onda 4) — exposes 7 thin remotes, one per sub-contract.
/// Cache (A17-v2) and sync+use_cases+facade (A18-v2) are rebuilt in
/// follow-up tickets; their previous exports were removed alongside
/// the deleted `SocialCareContract` god-class.
library;

export 'src/remote/assessment_remote.dart';
export 'src/remote/audit_remote.dart';
export 'src/remote/care_remote.dart';
export 'src/remote/health_remote.dart';
export 'src/remote/lookup_remote.dart';
export 'src/remote/protection_remote.dart';
export 'src/remote/registry_remote.dart';
