import 'package:core_contracts/core_contracts.dart';

/// Intent for `GET /lookups/{tableName}` — fetch a single lookup table.
///
/// Path-only shape (mirrors A08 [GetPatientIntent]): the route param is
/// injected straight from the shelf router; no `parseFromBody` exists.
final class GetLookupTableIntent with Equatable {
  const GetLookupTableIntent({required this.tableName});

  final String tableName;

  @override
  List<Object?> get props => [tableName];
}
