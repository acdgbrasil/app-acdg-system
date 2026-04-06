import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/handlers/lookup_handler.dart';

import 'test_helpers.dart';

void main() {
  group('LookupHandler', () {
    late FakeSocialCareBff fakeBff;
    late LookupHandler handler;

    setUp(() {
      fakeBff = FakeSocialCareBff(delay: Duration.zero);
      handler = LookupHandler(contractFactory: (_) => fakeBff);
    });

    group('GET /lookups/<tableName>', () {
      test('returns empty list from fake', () async {
        final request = testRequest('GET', '/lookups/dominio_parentesco');
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));

        final body = jsonDecode(await response.readAsString()) as List;
        expect(body, isEmpty);
      });

      test('returns JSON with correct content-type', () async {
        final request = testRequest('GET', '/lookups/any_table');
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
        expect(response.headers['content-type'], equals('application/json'));
      });
    });
  });
}
