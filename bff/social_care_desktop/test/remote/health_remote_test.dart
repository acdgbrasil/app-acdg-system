/// RED-phase tests for `HealthRemote` (A16-v2).
///
/// `HealthRemote implements HealthContract`. Two methods:
///   * `checkHealth()` → `GET /health`
///   * `checkReady()` → `GET /ready`
///
/// Both return `Future<Result<void>>` — `Success(null)` on 2xx, the
/// network-thrown error wrapped in `Failure(e)` otherwise.
///
/// Health probes intentionally do NOT use the `_backendFailure` helper:
/// they are liveness/readiness signals where the only meaningful answer
/// is "alive vs not alive". Non-2xx is therefore mapped via `Failure(e)`
/// (where `e` is the wrapped DioException) just like a network throw.
/// This mirrors the legacy behavior in `social_care_bff_remote.dart`
/// lines 91-109.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:social_care_desktop/src/remote/health_remote.dart';
import 'package:test/test.dart';

import '_mock_dio.dart';

void main() {
  group('HealthRemote', () {
    late MockDio dio;
    late HealthRemote remote;

    setUp(() {
      dio = MockDio();
      remote = HealthRemote(dio: dio);
    });

    test('implements HealthContract', () {
      expect(remote, isA<HealthContract>());
    });

    group('checkHealth', () {
      test('hits GET /health on success', () async {
        dio.nextStatusCode = 200;

        final result = await remote.checkHealth();

        expect(dio.lastMethod, equals('GET'));
        expect(dio.lastPath, equals('/health'));
        expect(result, isA<Success<void>>());
      });

      test('returns Failure when Dio throws (network down)', () async {
        dio.nextThrow = Exception('connection refused');

        final result = await remote.checkHealth();

        expect(result, isA<Failure<void>>());
      });
    });

    group('checkReady', () {
      test('hits GET /ready on success', () async {
        dio.nextStatusCode = 200;

        final result = await remote.checkReady();

        expect(dio.lastMethod, equals('GET'));
        expect(dio.lastPath, equals('/ready'));
        expect(result, isA<Success<void>>());
      });

      test('returns Failure when Dio throws (dependency down)', () async {
        dio.nextThrow = Exception('postgres unreachable');

        final result = await remote.checkReady();

        expect(result, isA<Failure<void>>());
      });
    });
  });
}
