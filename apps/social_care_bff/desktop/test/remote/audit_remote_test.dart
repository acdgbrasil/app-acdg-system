/// RED-phase tests for `AuditRemote` (A16-v2).
///
/// `AuditRemote implements AuditContract`. One method:
///   * `getAuditTrail(patientId, {eventType, limit, offset})`
///     → `GET /api/v1/patients/{patientId}/audit-trail`
///
/// Backend path is canonical from
/// `social-care/Sources/.../IO/HTTP/Controllers/PatientController.swift`
/// (`read.get(":patientId", "audit-trail", use: getAuditTrail)`).
///
/// Successful response shape is
/// `{ "data": [AuditTrailEntryResponse...], "meta": { "timestamp": "..." } }`.
/// Optional filters become query params (`eventType`, `limit`, `offset`).
/// When all filters are null, no query params should be sent.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:social_care_desktop/src/remote/audit_remote.dart';
import 'package:test/test.dart';

import '../_test_uuids.dart';
import '_mock_dio.dart';

void main() {
  group('AuditRemote', () {
    late MockDio dio;
    late AuditRemote remote;

    setUp(() {
      dio = MockDio();
      remote = AuditRemote(dio: dio);
    });

    test('implements AuditContract', () {
      expect(remote, isA<AuditContract>());
    });

    group('getAuditTrail', () {
      test(
        'hits GET /api/v1/patients/<id>/audit-trail with no filters',
        () async {
          dio.nextStatusCode = 200;
          dio.nextResponseData = <String, dynamic>{
            'data': <Map<String, dynamic>>[],
            'meta': <String, dynamic>{'timestamp': '2026-04-29T10:00:00.000Z'},
          };

          final result = await remote.getAuditTrail(kPatientUuid);

          expect(dio.lastMethod, equals('GET'));
          expect(
            dio.lastPath,
            equals('/api/v1/patients/$kPatientUuid/audit-trail'),
          );
          expect(
            result,
            isA<Success<StandardResponse<List<AuditTrailEntryResponse>>>>(),
          );
        },
      );

      test('forwards eventType, limit, offset as query parameters', () async {
        dio.nextStatusCode = 200;
        dio.nextResponseData = <String, dynamic>{
          'data': <Map<String, dynamic>>[],
          'meta': <String, dynamic>{'timestamp': '2026-04-29T10:00:00.000Z'},
        };

        await remote.getAuditTrail(
          kPatientUuid,
          eventType: 'PatientCreated',
          limit: 50,
          offset: 100,
        );

        expect(dio.lastQueryParameters?['eventType'], equals('PatientCreated'));
        expect(dio.lastQueryParameters?['limit'], equals(50));
        expect(dio.lastQueryParameters?['offset'], equals(100));
      });

      test('parses entries on 200 into typed Result', () async {
        dio.nextStatusCode = 200;
        dio.nextResponseData = <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': kAuditUuid,
              'aggregateId': kPatientUuid,
              'eventType': 'PatientCreated',
              'occurredAt': '2026-04-29T09:59:00.000Z',
              'recordedAt': '2026-04-29T09:59:01.000Z',
              'payload': <String, dynamic>{},
            },
          ],
          'meta': <String, dynamic>{'timestamp': '2026-04-29T10:00:00.000Z'},
        };

        final result = await remote.getAuditTrail(kPatientUuid);

        switch (result) {
          case Success(:final value):
            expect(value.data, hasLength(1));
            expect(value.data.first.id, equals(kAuditUuid));
            expect(value.data.first.eventType, equals('PatientCreated'));
          case Failure():
            fail('Expected Success on 200 with valid body');
        }
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 403;
          dio.nextResponseData = kBackendErrorBody(
            code: 'AUDIT-403',
            message: 'forbidden',
            http: 403,
          );

          final result = await remote.getAuditTrail(kPatientUuid);

          switch (result) {
            case Success():
              fail('Expected Failure on 403');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('AUDIT-403'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('socket hang up');

        final result = await remote.getAuditTrail(kPatientUuid);

        expect(
          result,
          isA<Failure<StandardResponse<List<AuditTrailEntryResponse>>>>(),
        );
      });

      // T1.3 regression: long audit trails (>50 entries) take the
      // Isolate.run threshold path. Audit trail can grow to 1000+
      // entries on long-lived patient records (compliance-relevant
      // history). Behavior contract MUST be identical to inline path.
      test(
        'parses long audit trail (200 entries) — exercises Isolate '
        'threshold path (T1.3 regression)',
        () async {
          final entries = List<Map<String, dynamic>>.generate(200, (i) {
            return <String, dynamic>{
              'id': 'audit-${i.toString().padLeft(4, '0')}',
              'aggregateId': kPatientUuid,
              'eventType': i.isEven ? 'PatientCreated' : 'PatientUpdated',
              'payload': <String, dynamic>{'index': i, 'note': 'entry $i'},
              'occurredAt': '2026-01-${(i % 28) + 1}T10:00:00.000Z',
              'recordedAt': '2026-01-${(i % 28) + 1}T10:00:01.000Z',
            };
          });
          dio.nextStatusCode = 200;
          dio.nextResponseData = <String, dynamic>{
            'data': entries,
            'meta': <String, dynamic>{'timestamp': '2026-05-01T12:00:00.000Z'},
          };

          final result = await remote.getAuditTrail(kPatientUuid);

          switch (result) {
            case Success(:final value):
              // Behavior preservation contract:
              // 1. Same number of entries
              expect(value.data, hasLength(200));
              // 2. Same ordering
              expect(value.data.first.id, equals('audit-0000'));
              expect(value.data.last.id, equals('audit-0199'));
              // 3. Field round-trip across isolate boundary
              expect(value.data[100].eventType, equals('PatientCreated'));
              expect(value.data[100].payload?['index'], equals(100));
              expect(value.data[100].payload?['note'], equals('entry 100'));
            case Failure():
              fail('Expected Success on 200 with 200-entry trail');
          }
        },
      );
    });
  });
}
