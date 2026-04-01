import 'package:persistence/persistence.dart';
import 'package:test/test.dart';

void main() {
  group('Drift data class immutability tests', () {
    test('CachedPatient should hold all fields', () {
      final now = DateTime.now();
      final patient = CachedPatient(
        id: 1,
        patientId: 'P123',
        personId: 'PERS123',
        firstName: 'João',
        lastName: 'Silva',
        cpf: '12345678901',
        fullRecordJson: '{}',
        version: 1,
        isDirty: true,
        lastSyncAt: now,
      );

      expect(patient.personId, 'PERS123');
      expect(patient.version, 1);
      expect(patient.isDirty, isTrue);
      expect(patient.patientId, 'P123');
    });

    test('CachedLookup should hold all fields', () {
      final now = DateTime.now();
      final lookup = CachedLookup(
        id: 1,
        lookupName: 'dominio_parentesco',
        itemsJson: '[{"code": "1", "description": "Pai"}]',
        lastFetchedAt: now,
      );

      expect(lookup.itemsJson, contains('Pai'));
      expect(lookup.lastFetchedAt, now);
      expect(lookup.lookupName, 'dominio_parentesco');
    });

    test('SyncAction should hold all fields including retry metadata', () {
      final now = DateTime.now();
      final nextRetry = now.add(const Duration(minutes: 5));
      final action = SyncAction(
        id: 1,
        actionId: 'A123',
        patientId: 'P123',
        actionType: 'REGISTER_PATIENT',
        payloadJson: '{}',
        timestamp: now,
        status: 'CONFLICT',
        retryCount: 2,
        nextRetryAt: nextRetry,
        conflictDetails: 'Version mismatch',
      );

      expect(action.retryCount, 2);
      expect(action.nextRetryAt, nextRetry);
      expect(action.conflictDetails, 'Version mismatch');
      expect(action.status, 'CONFLICT');
    });
  });
}
