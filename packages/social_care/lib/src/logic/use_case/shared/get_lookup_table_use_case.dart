import 'package:core/core.dart';
import 'package:shared/shared.dart';

import '../../../data/repositories/lookup_repository.dart';

/// Retrieves a lookup table by its domain name.
///
/// Encapsulates [LookupRepository.getLookupTable] behind the standard
/// [BaseUseCase] contract so that ViewModels never access repositories
/// directly.
class GetLookupTableUseCase extends BaseUseCase<String, List<LookupItem>> {
  GetLookupTableUseCase({required LookupRepository lookupRepository})
    : _lookupRepository = lookupRepository;

  final LookupRepository _lookupRepository;

  @override
  Future<Result<List<LookupItem>>> execute(String tableName) {
    return _lookupRepository.getLookupTable(tableName);
  }
}
