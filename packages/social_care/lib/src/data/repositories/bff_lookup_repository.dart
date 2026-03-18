import 'package:core/core.dart';
import 'package:shared/shared.dart';

import 'lookup_repository.dart';

/// [LookupRepository] implementation backed by the Social Care BFF.
class BffLookupRepository implements LookupRepository {
  BffLookupRepository({required SocialCareContract bff}) : _bff = bff;

  final SocialCareContract _bff;

  @override
  Future<Result<List<LookupItem>>> getLookupTable(String tableName) {
    return _bff.getLookupTable(tableName);
  }
}
