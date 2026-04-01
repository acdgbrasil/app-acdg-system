import 'package:core/core.dart';
import 'package:shared/shared.dart';

/// Safely parses an enum from a SCREAMING_SNAKE_CASE JSON string.
///
/// Returns [Failure] with context if [json] is null or no match is found.
Result<T> enumFromJson<T extends Enum>(
  List<T> values,
  dynamic json,
  String field,
) {
  if (json == null) return Failure('$field is required but was null');
  final str = json as String;
  final match = values
      .where((v) => v.name.toSnakeCaseUpper() == str)
      .firstOrNull;
  return match != null
      ? Success(match)
      : Failure('Unknown $field value: "$str"');
}

/// Parses a nullable sub-object. Returns `Success(null)` when [json] is null,
/// otherwise delegates to [parse].
Result<T?> optionalFromJson<T>(
  dynamic json,
  Result<T> Function(Map<String, dynamic>) parse,
) {
  if (json == null) return const Success(null);
  return parse(json as Map<String, dynamic>).map((v) => v as T?);
}

/// Parses a JSON list into domain objects. Fails on the first invalid item.
Result<List<T>> listFromJson<T>(
  dynamic json,
  Result<T> Function(Map<String, dynamic>) parse, {
  String field = 'list',
}) {
  final items = json as List? ?? [];
  final results = <T>[];
  for (final (i, item) in items.indexed) {
    switch (parse(item as Map<String, dynamic>)) {
      case Success(:final value):
        results.add(value);
      case Failure(:final error):
        return Failure('$field[$i]: $error');
    }
  }
  return Success(results);
}

/// Parses a UUID-based ID. Returns [Failure] with [field] context on error.
Result<T> idFromJson<T>(
  Result<T> Function(String?) create,
  dynamic json,
  String field,
) {
  switch (create(json as String?)) {
    case Success(:final value):
      return Success(value);
    case Failure(:final error):
      return Failure('$field: $error');
  }
}

/// Parses a UUID-based ID with a fallback for null/empty values.
Result<T> idFromJsonOrDefault<T>(
  Result<T> Function(String?) create,
  dynamic json,
  String fallback,
) {
  final raw = json as String?;
  return create(raw != null && raw.isNotEmpty ? raw : fallback);
}

/// Default UUID used when the server omits an optional ID field.
const defaultUuid = '00000000-0000-0000-0000-000000000000';
