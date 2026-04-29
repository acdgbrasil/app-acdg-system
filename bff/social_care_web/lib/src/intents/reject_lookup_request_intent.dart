import 'package:core_contracts/core_contracts.dart';

/// Intent for `PUT /lookup-requests/{id}/reject` — admin rejects a
/// pending governance request.
///
/// Path-only shape (mirrors A08 [GetPatientIntent]): the route param is
/// injected straight from the shelf router; no `parseFromBody` exists.
final class RejectLookupRequestIntent with Equatable {
  const RejectLookupRequestIntent({required this.requestId});

  final String requestId;

  @override
  List<Object?> get props => [requestId];
}
