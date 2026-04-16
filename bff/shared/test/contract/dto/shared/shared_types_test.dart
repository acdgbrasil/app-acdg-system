import 'dart:convert';

import 'package:test/test.dart';
import 'package:shared/shared.dart';

void main() {
  group('PaginationMeta', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'pageSize': 20,
        'totalCount': 150,
        'hasMore': true,
        'nextCursor': 'abc123cursor',
      };
      final dto = PaginationMeta.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with nextCursor null', () {
      final json = {
        'pageSize': 10,
        'totalCount': 5,
        'hasMore': false,
        'nextCursor': null,
      };
      final dto = PaginationMeta.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('PaginatedList<String>', () {
    test('should round-trip with populated data', () {
      final json = {
        'data': ['item1', 'item2', 'item3'],
        'meta': {
          'pageSize': 10,
          'totalCount': 3,
          'hasMore': false,
          'nextCursor': null,
        },
      };
      final dto = PaginatedList<String>.fromJson(json, (obj) => obj as String);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson((v) => v)));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });

    test('should round-trip with empty data', () {
      final json = {
        'data': <String>[],
        'meta': {
          'pageSize': 25,
          'totalCount': 0,
          'hasMore': false,
          'nextCursor': null,
        },
      };
      final dto = PaginatedList<String>.fromJson(json, (obj) => obj as String);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson((v) => v)));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });
  });

  group('ErrorObservability', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'category': 'validation',
        'severity': 'warning',
        'fingerprint': ['PAT', '001', 'cpf'],
        'tags': {'bc': 'registry', 'layer': 'domain'},
      };
      final dto = ErrorObservability.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with minimal fields', () {
      final json = {
        'category': null,
        'severity': null,
        'fingerprint': <String>[],
        'tags': <String, String>{},
      };
      final dto = ErrorObservability.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should use defaults when fields are absent', () {
      final json = <String, dynamic>{};
      final dto = ErrorObservability.fromJson(json);
      expect(dto.fingerprint, isEmpty);
      expect(dto.tags, isEmpty);
      expect(dto.category, isNull);
      expect(dto.severity, isNull);
    });
  });

  group('BackendError', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'id': 'err-550e8400-e29b-41d4-a716-446655440000',
        'code': 'PAT-001',
        'message': 'CPF invalido',
        'bc': 'registry',
        'module': 'patient',
        'kind': 'validation',
        'context': {'field': 'cpf', 'value': '000'},
        'safeContext': {'field': 'cpf'},
        'observability': {
          'category': 'validation',
          'severity': 'error',
          'fingerprint': ['PAT', '001'],
          'tags': {'bc': 'registry'},
        },
        'http': 422,
        'stackTrace': 'at Patient.validate(line 42)',
        'cause': null,
      };
      final dto = BackendError.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });

    test('should round-trip with minimal required fields only', () {
      final json = {
        'id': 'err-001',
        'code': 'GEN-500',
        'message': 'Internal server error',
        'bc': null,
        'module': null,
        'kind': null,
        'context': null,
        'safeContext': null,
        'observability': null,
        'http': null,
        'stackTrace': null,
        'cause': null,
      };
      final dto = BackendError.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });

    test('should round-trip with recursive cause chain', () {
      final json = {
        'id': 'err-outer',
        'code': 'APP-001',
        'message': 'Use case failed',
        'bc': 'care',
        'module': null,
        'kind': null,
        'context': null,
        'safeContext': null,
        'observability': null,
        'http': 500,
        'stackTrace': null,
        'cause': {
          'id': 'err-inner',
          'code': 'DB-001',
          'message': 'Connection refused',
          'bc': null,
          'module': null,
          'kind': null,
          'context': null,
          'safeContext': null,
          'observability': null,
          'http': null,
          'stackTrace': null,
          'cause': null,
        },
      };
      final dto = BackendError.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });
  });

  group('BackendErrorResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'error': {
          'id': 'err-001',
          'code': 'PAT-002',
          'message': 'Patient not found',
          'bc': 'registry',
          'module': null,
          'kind': null,
          'context': null,
          'safeContext': null,
          'observability': null,
          'http': 404,
          'stackTrace': null,
          'cause': null,
        },
        'details': {'patientId': '550e8400-e29b-41d4-a716-446655440000'},
      };
      final dto = BackendErrorResponse.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });

    test('should round-trip with details null', () {
      final json = {
        'error': {
          'id': 'err-002',
          'code': 'GEN-403',
          'message': 'Forbidden',
          'bc': null,
          'module': null,
          'kind': null,
          'context': null,
          'safeContext': null,
          'observability': null,
          'http': 403,
          'stackTrace': null,
          'cause': null,
        },
        'details': null,
      };
      final dto = BackendErrorResponse.fromJson(json);
      final roundTripped = jsonDecode(jsonEncode(dto.toJson()));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });
  });

  group('ResponseMeta', () {
    test('should round-trip with timestamp', () {
      final json = {'timestamp': '2026-04-16T10:30:00Z'};
      final dto = ResponseMeta.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('IdData', () {
    test('should round-trip with valid UUID', () {
      final json = {'id': '550e8400-e29b-41d4-a716-446655440000'};
      final dto = IdData.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('StandardResponse<Map<String, dynamic>>', () {
    test('should round-trip with Map data', () {
      final json = {
        'data': {'name': 'Maria Silva', 'age': 35},
        'meta': {'timestamp': '2026-04-16T10:30:00Z'},
      };
      final dto = StandardResponse<Map<String, dynamic>>.fromJson(
        json,
        (obj) => obj as Map<String, dynamic>,
      );
      final roundTripped = jsonDecode(jsonEncode(dto.toJson((v) => v)));
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });
  });

  group('StandardResponse<IdData>', () {
    test('should round-trip as StandardIdResponse', () {
      final json = {
        'data': {'id': '550e8400-e29b-41d4-a716-446655440000'},
        'meta': {'timestamp': '2026-04-16T14:00:00Z'},
      };
      final dto = StandardIdResponse.fromJson(
        json,
        (obj) => IdData.fromJson(obj as Map<String, dynamic>),
      );
      final roundTripped = jsonDecode(
        jsonEncode(dto.toJson((v) => v.toJson())),
      );
      final original = jsonDecode(jsonEncode(json));
      expect(roundTripped, equals(original));
    });
  });
}
