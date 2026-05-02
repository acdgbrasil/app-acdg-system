import 'package:core_contracts/core_contracts.dart';

/// Intent for `GET /lookup-requests` — list governance requests.
///
/// Empty value object: no fields, no parser. All instances compare equal
/// (Equatable.props is `const []`).
final class GetLookupRequestsIntent with Equatable {
  const GetLookupRequestsIntent();

  @override
  List<Object?> get props => const [];
}
