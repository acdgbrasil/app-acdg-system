import 'package:shared/shared.dart';

abstract class LocalCacheContract implements SocialCareContract {
  Future<bool> hasPendingActions(String patientId);

  Future<void> updateCacheFromRemote(PatientResponse dto);

  Future<void> updateCacheFromSummaries(List<PatientSummaryResponse> summaries);

  Future<void> updateLookupCache(
    String tableName,
    List<Map<String, dynamic>> items,
  );
}
