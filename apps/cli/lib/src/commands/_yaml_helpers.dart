/// Shared YAML→JSON helpers for `--from-yaml` payload overrides.
///
/// Originally inlined in `patient_register_command.dart` (C03). Extracted
/// here in C05 so all seven `acdg assessment <verb>` commands consume the
/// same conversion routine instead of carrying their own copies. Future
/// commands (`care`, `protection`) reusing `--from-yaml` should import this
/// module too.
///
/// Two responsibilities:
///   1. Walk a `YamlMap`/`YamlList` tree and rebuild it as plain
///      `Map<String, Object?>`/`List<Object?>` so the result is `jsonEncode`-
///      friendly. The `yaml` package returns `YamlMap` (a `Map`) but Dio's
///      JSON encoder doesn't know how to serialize it without conversion.
///   2. Read a YAML file via the injected `fileReader`, parse it, and
///      surface filesystem / parse errors as [InvalidArgError] [Failure]s.
///      This is the adapter boundary — the only place under `commands/`
///      where `try/catch` is allowed.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:yaml/yaml.dart';

import '../errors/cli_error.dart';

/// Recursively converts a YAML node into a plain Dart JSON-shaped tree.
///
/// `YamlMap` → `Map<String, Object?>`. `YamlList` → `List<Object?>`. Scalar
/// leaves pass through unchanged. Plain `Map`/`List` (already-converted
/// subtrees, or fixtures coming from `loadYamlNode`) are walked too.
Object? yamlToJsonNode(Object? node) {
  if (node is YamlMap) {
    return <String, Object?>{
      for (final entry in node.entries)
        entry.key.toString(): yamlToJsonNode(entry.value),
    };
  }
  if (node is YamlList) {
    return [for (final item in node) yamlToJsonNode(item)];
  }
  if (node is Map) {
    return <String, Object?>{
      for (final entry in node.entries)
        entry.key.toString(): yamlToJsonNode(entry.value),
    };
  }
  if (node is List) {
    return [for (final item in node) yamlToJsonNode(item)];
  }
  return node;
}

/// Coerces [yamlToJsonNode] output to a `Map<String, Object?>`. Falls back
/// to an empty map when the root is not a map (caller is responsible for
/// rejecting non-map roots BEFORE this is called — see [readYamlBody]).
Map<String, Object?> yamlToJsonMap(Object? node) {
  final converted = yamlToJsonNode(node);
  return converted is Map<String, Object?> ? converted : const {};
}

/// Reads [path] via [fileReader], parses YAML, and returns the resulting
/// JSON-shaped Map wrapped in a [Result]. Adapter boundary — file I/O and
/// YAML parsing are translated to [InvalidArgError] here so callers can
/// stay `try`-free.
///
/// Failure modes:
///   * `fileReader` throws (e.g. `FileSystemException`) →
///     `InvalidArgError('Cannot read --from-yaml file at "<path>": ...')`.
///   * `loadYaml` throws `YamlException` →
///     `InvalidArgError('Invalid YAML in "<path>": ...')`.
///   * Top-level node is not a map →
///     `InvalidArgError('YAML at "<path>" must be a map at the top level.')`.
Future<Result<Map<String, Object?>>> readYamlBody({
  required String path,
  required Future<String> Function(String path) fileReader,
}) async {
  String contents;
  try {
    contents = await fileReader(path);
    // ignore: unused_catch_stack
  } on Object catch (e, st) {
    return Failure<Map<String, Object?>>(
      InvalidArgError('Cannot read --from-yaml file at "$path": $e'),
    );
  }
  final Object? parsed;
  try {
    parsed = loadYaml(contents);
    // ignore: unused_catch_stack
  } on YamlException catch (e, st) {
    return Failure<Map<String, Object?>>(
      InvalidArgError('Invalid YAML in "$path": $e'),
    );
  }
  if (parsed is! YamlMap && parsed is! Map) {
    return Failure<Map<String, Object?>>(
      InvalidArgError('YAML at "$path" must be a map at the top level.'),
    );
  }
  return Success(yamlToJsonMap(parsed));
}
