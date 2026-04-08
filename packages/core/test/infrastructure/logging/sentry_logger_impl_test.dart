import 'package:flutter_test/flutter_test.dart';
import 'package:core/src/infrastructure/logging/log_level.dart';
import 'package:core/src/infrastructure/logging/sentry_logger_impl.dart';
import '../../testing/fakes/fake_sentry_client.dart';

void main() {
  group('SentryLoggerImpl - Regras de Despacho (DIP & Fakes Manuais)', () {
    late FakeSentryClient fakeSentryClient;
    late SentryLoggerImpl logger;

    setUp(() {
      fakeSentryClient = FakeSentryClient();
      logger = SentryLoggerImpl(sentryClient: fakeSentryClient);
    });

    test('NÃO deve enviar para o Sentry quando o LogLevel for INFO', () {
      logger.log('Usuário acessou a tela', LogLevel.info);

      expect(fakeSentryClient.capturedMessages, isEmpty);
      expect(fakeSentryClient.capturedExceptions, isEmpty);
    });

    test('NÃO deve enviar para o Sentry quando o LogLevel for WARNING', () {
      logger.log('Conexão instável', LogLevel.warning);

      expect(fakeSentryClient.capturedMessages, isEmpty);
      expect(fakeSentryClient.capturedExceptions, isEmpty);
    });

    test(
      'DEVE enviar captureException para o Sentry quando o LogLevel for ERROR com exception atrelada',
      () {
        final exception = Exception('Falha grave na API');
        final stackTrace = StackTrace.current;

        logger.log(
          'Falha na requisição',
          LogLevel.error,
          error: exception,
          stackTrace: stackTrace,
        );

        expect(fakeSentryClient.capturedExceptions, hasLength(1));
        expect(fakeSentryClient.capturedExceptions.first, equals(exception));
        expect(fakeSentryClient.capturedMessages, isEmpty);
      },
    );

    test(
      'DEVE enviar captureMessage para o Sentry quando o LogLevel for FATAL sem exception explícita',
      () {
        logger.log('Estado da ViewModel inconsistente', LogLevel.fatal);

        expect(fakeSentryClient.capturedMessages, hasLength(1));
        expect(
          fakeSentryClient.capturedMessages.first,
          equals('Estado da ViewModel inconsistente'),
        );
      },
    );

    test(
      'DEVE enviar captureException quando LogLevel for FATAL com exception',
      () {
        final exception = Exception('Crash fatal');

        logger.log('App crashed', LogLevel.fatal, error: exception);

        expect(fakeSentryClient.capturedExceptions, hasLength(1));
        expect(fakeSentryClient.capturedExceptions.first, equals(exception));
        expect(fakeSentryClient.capturedMessages, isEmpty);
      },
    );

    test(
      'NÃO deve enviar para o Sentry quando LogLevel for ERROR sem error object',
      () {
        logger.log('Erro sem throwable', LogLevel.error);

        expect(fakeSentryClient.capturedExceptions, isEmpty);
        expect(fakeSentryClient.capturedMessages, isEmpty);
      },
    );

    test(
      'DEVE capturar Error types (não apenas Exception) quando LogLevel for ERROR',
      () {
        final error = TypeError();

        logger.log('TypeError capturado', LogLevel.error, error: error);

        expect(fakeSentryClient.capturedExceptions, hasLength(1));
        expect(fakeSentryClient.capturedExceptions.first, isA<TypeError>());
      },
    );
  });

  group('SentryClientAdapter - User & Breadcrumb', () {
    late FakeSentryClient fakeSentryClient;

    setUp(() {
      fakeSentryClient = FakeSentryClient();
    });

    test('DEVE registrar user context com setUser', () {
      fakeSentryClient.setUser(
        id: 'user-123',
        email: 'test@acdg.com',
        username: 'testuser',
      );

      expect(fakeSentryClient.users, hasLength(1));
      expect(fakeSentryClient.users.first['id'], equals('user-123'));
      expect(fakeSentryClient.users.first['email'], equals('test@acdg.com'));
      expect(fakeSentryClient.userCleared, isFalse);
    });

    test('DEVE limpar user context com clearUser', () {
      fakeSentryClient.setUser(id: 'user-123');
      fakeSentryClient.clearUser();

      expect(fakeSentryClient.userCleared, isTrue);
    });

    test('DEVE registrar breadcrumbs com message e category', () {
      fakeSentryClient.addBreadcrumb(
        message: 'Patient loaded',
        category: 'home',
        data: {'patientId': '456'},
      );

      expect(fakeSentryClient.breadcrumbs, hasLength(1));
      expect(fakeSentryClient.breadcrumbs.first['message'], 'Patient loaded');
      expect(fakeSentryClient.breadcrumbs.first['category'], 'home');
      expect(
        (fakeSentryClient.breadcrumbs.first['data'] as Map)['patientId'],
        '456',
      );
    });
  });
}
