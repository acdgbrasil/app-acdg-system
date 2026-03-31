import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';

/// In-memory [LookupRepository] for testing.
///
/// Returns pre-configured lookup tables from a simple map.
class InMemoryLookupRepository implements LookupRepository {
  final Map<String, List<LookupItem>> _tables = {};

  /// Seeds a lookup table with items.
  void seed(String tableName, List<LookupItem> items) {
    _tables[tableName] = items;
  }

  /// Clears all stored tables.
  void clear() => _tables.clear();

  @override
  Future<Result<List<LookupItem>>> getLookupTable(String tableName) async {
    final items = _tables[tableName];
    if (items != null) return Success(items);
    return const Success([]);
  }
}
