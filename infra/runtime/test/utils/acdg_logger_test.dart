import 'package:flutter_test/flutter_test.dart';
import 'package:core/src/infrastructure/logging/log_level.dart';
import 'package:core/src/infrastructure/logging/sentry_logger_impl.dart';
import '../testing/fakes/fake_sentry_client.dart';

void main() {
  group('AcdgLogger Observability Integration', () {
    late FakeSentryClient fakeSentry;
    late SentryLoggerImpl logger;

    setUp(() {
      fakeSentry = FakeSentryClient();
      logger = SentryLoggerImpl(sentryClient: fakeSentry);
    });

    test('INFO logs are local-only — Sentry receives nothing', () {
      logger.log('User opened screen', LogLevel.info);

      expect(fakeSentry.capturedMessages, isEmpty);
      expect(fakeSentry.capturedExceptions, isEmpty);
    });

    test('WARNING logs are local-only — Sentry receives nothing', () {
      logger.log('Unstable connection', LogLevel.warning);

      expect(fakeSentry.capturedMessages, isEmpty);
      expect(fakeSentry.capturedExceptions, isEmpty);
    });

    test('ERROR with exception sends captureException to Sentry', () {
      final exception = Exception('API failure');
      logger.log(
        'Request failed',
        LogLevel.error,
        error: exception,
        stackTrace: StackTrace.current,
      );

      expect(fakeSentry.capturedExceptions, hasLength(1));
      expect(fakeSentry.capturedExceptions.first, equals(exception));
      expect(fakeSentry.capturedMessages, isEmpty);
    });

    test('FATAL without exception sends captureMessage to Sentry', () {
      logger.log('Inconsistent ViewModel state', LogLevel.fatal);

      expect(fakeSentry.capturedMessages, hasLength(1));
      expect(
        fakeSentry.capturedMessages.first,
        equals('Inconsistent ViewModel state'),
      );
    });
  });
}
