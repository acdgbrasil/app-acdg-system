import 'package:core/core.dart';
import 'package:shared/shared.dart';

/// Repository contract for Lookup table operations.
///
/// Lookup tables provide reference data (e.g., relationship types,
/// social identity types) used across the Social Care module.
abstract class LookupRepository {
  /// Fetches items from a domain lookup table by [tableName].
  Future<Result<List<LookupItem>>> getLookupTable(String tableName);
}
