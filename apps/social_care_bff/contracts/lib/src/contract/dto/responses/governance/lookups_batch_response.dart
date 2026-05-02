import 'package:core_contracts/core_contracts.dart';

import 'lookup_item_response.dart';

/// Response DTO for `GET /api/lookups?tables=a,b,c`.
///
/// Carries a map keyed by lookup table name, each holding the list of
/// [LookupItemResponse] items belonging to that table.
class LookupsBatchResponse with Equatable {
  const LookupsBatchResponse({required this.tables});

  factory LookupsBatchResponse.fromJson(Map<String, dynamic> json) {
    final rawTables = json['tables'] as Map<String, dynamic>;
    return LookupsBatchResponse(
      tables: rawTables.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map(
                (e) => LookupItemResponse.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      ),
    );
  }

  final Map<String, List<LookupItemResponse>> tables;

  Map<String, dynamic> toJson() => {
    'tables': tables.map(
      (key, value) =>
          MapEntry(key, value.map((e) => e.toJson()).toList()),
    ),
  };

  @override
  List<Object?> get props => [tables];
}
