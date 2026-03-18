import 'package:isar/isar.dart';

part 'cached_lookup.g.dart';

@collection
class CachedLookup {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String tableName;

  late String itemsJson;

  late DateTime lastFetchedAt;
}
