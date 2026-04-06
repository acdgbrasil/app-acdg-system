import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/handlers/health_handler.dart';

import 'test_helpers.dart';

/// A fake contract that fails health checks.
class _FailingContract extends FakeSocialCareBff {
  _FailingContract() : super(delay: Duration.zero);

  @override
  Future<Result<void>> checkHealth() async => const Failure('Service down');

  @override
  Future<Result<void>> checkReady() async =>
      const Failure('Database unreachable');
}

void main() {
  group('HealthHandler', () {
    late FakeSocialCareBff fakeBff;
    late HealthHandler handler;

    setUp(() {
      fakeBff = FakeSocialCareBff(delay: Duration.zero);
      handler = HealthHandler(contractFactory: (_) => fakeBff);
    });

    group('GET /health/live', () {
      test('returns 200 when service is healthy', () async {
        final request = testRequest('GET', '/health/live');
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));

        final body = jsonDecode(await response.readAsString());
        expect(body['status'], equals('ok'));
      });

      test('returns 503 when service is unhealthy', () async {
        final failingHandler = HealthHandler(
          contractFactory: (_) => _FailingContract(),
        );

        final request = testRequest('GET', '/health/live');
        final response = await failingHandler.router.call(request);

        expect(response.statusCode, equals(503));

        final body = jsonDecode(await response.readAsString());
        expect(body['error'], contains('Service down'));
      });
    });

    group('GET /health/ready', () {
      test('returns 200 when service is ready', () async {
        final request = testRequest('GET', '/health/ready');
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));

        final body = jsonDecode(await response.readAsString());
        expect(body['status'], equals('ready'));
      });

      test('returns 503 when service is not ready', () async {
        final failingHandler = HealthHandler(
          contractFactory: (_) => _FailingContract(),
        );

        final request = testRequest('GET', '/health/ready');
        final response = await failingHandler.router.call(request);

        expect(response.statusCode, equals(503));

        final body = jsonDecode(await response.readAsString());
        expect(body['error'], contains('Database unreachable'));
      });
    });
  });
}
