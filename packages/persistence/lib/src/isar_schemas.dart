import 'package:isar/isar.dart';

import 'schemas/cached_lookup.dart';
import 'schemas/cached_patient.dart';
import 'schemas/sync_action.dart';

class IsarSchemas {
  static List<CollectionSchema<dynamic>> get all => [
        CachedPatientSchema,
        CachedLookupSchema,
        SyncActionSchema,
      ];
}
