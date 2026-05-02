import 'package:test/test.dart';
import 'package:shared/shared.dart';

/// Round-trip tests for `ToggleLookupItemRequest`.
///
/// Contract A — Ação #34: PATCH `/api/lookups/{tableName}/{id}/toggle` (admin).
/// Payload: `{ active: bool }`.
///
/// These tests MUST FAIL initially — the DTO class does not yet exist.
void main() {
  group('ToggleLookupItemRequest', () {
    test('should round-trip with active=true', () {
      final json = {'active': true};
      final dto = ToggleLookupItemRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with active=false', () {
      final json = {'active': false};
      final dto = ToggleLookupItemRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('fromJson reads canonical BFF shape correctly', () {
      final json = {'active': true};

      final dto = ToggleLookupItemRequest.fromJson(json);

      expect(dto.active, isTrue);
    });

    test('toJson produces canonical BFF shape', () {
      final dto = ToggleLookupItemRequest(active: false);

      final json = dto.toJson();

      expect(json['active'], isFalse);
    });
  });
}
