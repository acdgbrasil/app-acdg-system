import 'package:persistence/persistence.dart';
import 'package:test/test.dart';

void main() {
  group('Schema Serialization Tests', () {
    test('CachedPatient should support new fields', () {
      final now = DateTime.now();
      final patient = CachedPatient()
        ..patientId = 'P123'
        ..personId = 'PERS123'
        ..firstName = 'João'
        ..lastName = 'Silva'
        ..cpf = '12345678901'
        ..fullRecordJson = '{}'
        ..version = 1
        ..isDirty = true
        ..lastSyncAt = now;

      expect(patient.personId, 'PERS123');
      expect(patient.version, 1);
      expect(patient.isDirty, isTrue);
    });

    test('CachedLookup should support new fields', () {
      final now = DateTime.now();
      final lookup = CachedLookup()
        ..tableName = 'dominio_parentesco'
        ..itemsJson = '[{"code": "1", "description": "Pai"}]'
        ..lastFetchedAt = now;

      expect(lookup.itemsJson, contains('Pai'));
      expect(lookup.lastFetchedAt, now);
    });

    test('SyncAction should support new fields', () {
      final now = DateTime.now();
      final nextRetry = now.add(const Duration(minutes: 5));
      final action = SyncAction()
        ..actionId = 'A123'
        ..patientId = 'P123'
        ..actionType = 'REGISTER_PATIENT'
        ..payloadJson = '{}'
        ..timestamp = now
        ..status = 'CONFLICT'
        ..retryCount = 2
        ..nextRetryAt = nextRetry
        ..conflictDetails = 'Version mismatch';

      expect(action.retryCount, 2);
      expect(action.nextRetryAt, nextRetry);
      expect(action.conflictDetails, 'Version mismatch');
    });
  });
}
