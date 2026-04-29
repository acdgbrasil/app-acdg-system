import 'package:core_contracts/core_contracts.dart';

/// Intent for `PUT /lookup-requests/{id}/approve` — admin approves a
/// pending governance request.
///
/// Path-only shape (mirrors A08 [GetPatientIntent]): the route param is
/// injected straight from the shelf router; no `parseFromBody` exists.
final class ApproveLookupRequestIntent with Equatable {
  const ApproveLookupRequestIntent({required this.requestId});

  final String requestId;

  @override
  List<Object?> get props => [requestId];
}
