import 'package:drift/drift.dart';

import 'acdg_database.drift.dart';
import 'tables/cached_lookups.dart';
import 'tables/cached_patients.dart';
import 'tables/sync_actions.dart';

@DriftDatabase(tables: [CachedPatients, SyncActions, CachedLookups])
class AcdgDatabase extends $AcdgDatabase {
  AcdgDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
